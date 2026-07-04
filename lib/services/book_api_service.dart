import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class BookApiService {
  static const String _googleBooksUrl =
      'https://www.googleapis.com/books/v1/volumes';
  static const String _openLibraryBooksUrl =
      'https://openlibrary.org/api/books';
  static const String _openLibrarySearchUrl =
      'https://openlibrary.org/search.json';
  static const Duration _requestTimeout = Duration(seconds: 6);

  // ============ Public API ============

  /// Search for a book by ISBN (10 or 13 digits).
  /// Falls back across Google Books → Open Library books API → Open Library
  /// search.json. If all ISBN lookups fail and [titleHint]+[authorHint] are
  /// provided, runs a title+author search as a last resort.
  Future<Map<String, dynamic>?> searchByIsbn(
    String isbn, {
    String? titleHint,
    String? authorHint,
  }) async {
    final cleanIsbn = isbn.replaceAll(RegExp(r'[^0-9Xx]'), '');

    // 1-3: Google Books, Open Library Books API, Open Library search.json all
    // query the same ISBN. Fire them concurrently, then return as soon as the
    // highest-priority source that has data resolves (Google > OL Books > OL
    // Search) — WITHOUT waiting for the slower, lower-priority requests. (A
    // plain Future.wait would block on the slowest of the three even when
    // Google already had the answer in ~300ms.)
    final googleFuture =
        _searchGoogleBooks('isbn:$cleanIsbn', fallbackIsbn: cleanIsbn)
            .catchError((_) => null);
    final olBooksFuture = _searchOpenLibraryBooksApi(
      cleanIsbn,
    ).catchError((_) => null);
    final olSearchFuture = _searchOpenLibrarySearch(
      isbn: cleanIsbn,
    ).catchError((_) => null);

    final google = await googleFuture;
    if (google != null) return normalizeBookMap(google);
    final olBooks = await olBooksFuture;
    if (olBooks != null) return normalizeBookMap(olBooks);
    final olSearch = await olSearchFuture;
    if (olSearch != null) return normalizeBookMap(olSearch);

    // 4. D&R scrape via Cloud Function (Turkish books missing from public APIs).
    final drResult = await _searchDrFallback(cleanIsbn)
        .timeout(const Duration(seconds: 6), onTimeout: () => null)
        .catchError((_) => null);
    if (drResult != null) return normalizeBookMap(drResult);

    // 5. Last resort: title+author hints
    final title = titleHint?.trim();
    final author = authorHint?.trim();
    if (title != null && title.isNotEmpty && author != null && author.isNotEmpty) {
      final hintResult = await searchByTitleAuthor(title, author);
      if (hintResult != null) {
        // Preserve the ISBN that was originally searched.
        return {...hintResult, 'isbn': hintResult['isbn'] ?? cleanIsbn};
      }
    }

    return null;
  }

  /// Search by free-form query (title, author, or any text).
  /// Kept for backward compatibility with [import_excel_sheet.dart].
  Future<Map<String, dynamic>?> searchBook(String query) async {
    return _searchGoogleBooks(query);
  }

  /// Search by explicit title + author. Tries Google Books with structured
  /// `intitle:` / `inauthor:` operators first, then Open Library search.json.
  Future<Map<String, dynamic>?> searchByTitleAuthor(
    String title,
    String author,
  ) async {
    final encodedTitle = Uri.encodeQueryComponent(title);
    final encodedAuthor = Uri.encodeQueryComponent(author);

    // 1. Google Books structured query
    final google = await _searchGoogleBooks(
      'intitle:$encodedTitle+inauthor:$encodedAuthor',
    );
    if (google != null) return normalizeBookMap(google);

    // 2. Open Library search.json
    final ol = await _searchOpenLibrarySearch(title: title, author: author);
    return ol == null ? null : normalizeBookMap(ol);
  }

  // ============ Google Books ============

  Future<Map<String, dynamic>?> _searchGoogleBooks(
    String query, {
    String? fallbackIsbn,
  }) async {
    try {
      final url = Uri.parse('$_googleBooksUrl?q=$query&maxResults=1');
      debugPrint('[BookAPI] Google Books: $query');

      final response = await http.get(url).timeout(_requestTimeout);
      if (response.statusCode != 200) return null;

      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data['totalItems'] == 0 || data['items'] == null) return null;

      final item = data['items'][0];
      String? isbnHint = fallbackIsbn;
      if (isbnHint == null && query.startsWith('isbn:')) {
        isbnHint = query.replaceFirst('isbn:', '');
      }
      return _parseGoogleBooksItem(item, isbnHint ?? '');
    } catch (e) {
      debugPrint('[BookAPI] Google Books error: $e');
      return null;
    }
  }

  Map<String, dynamic> _parseGoogleBooksItem(
    Map<String, dynamic> item,
    String searchedIsbn,
  ) {
    final volumeInfo = item['volumeInfo'] as Map<String, dynamic>;

    String author = '';
    if (volumeInfo['authors'] != null) {
      author = (volumeInfo['authors'] as List).join(', ');
    }

    String genre = 'Other';
    if (volumeInfo['categories'] != null &&
        (volumeInfo['categories'] as List).isNotEmpty) {
      genre = (volumeInfo['categories'] as List).join(' / ');
    }

    String? isbn;
    if (volumeInfo['industryIdentifiers'] != null) {
      for (var identifier in volumeInfo['industryIdentifiers']) {
        if (identifier['type'] == 'ISBN_13') {
          isbn = identifier['identifier'];
          break;
        } else if (identifier['type'] == 'ISBN_10' && isbn == null) {
          isbn = identifier['identifier'];
        }
      }
    }
    isbn ??= searchedIsbn;

    final coverUrl = _resolveGoogleBooksCover(volumeInfo['imageLinks'], isbn);

    String? purchaseLink;
    final saleInfo = item['saleInfo'];
    final isEbook = saleInfo?['isEbook'] == true;
    if (saleInfo != null && saleInfo['buyLink'] != null && !isEbook) {
      purchaseLink = saleInfo['buyLink'];
    } else if (isbn.isNotEmpty) {
      purchaseLink = 'https://www.amazon.com.tr/s?k=$isbn';
    }

    return {
      'title': volumeInfo['title'] ?? '',
      'author': author,
      'description': volumeInfo['description'],
      'pageCount': volumeInfo['pageCount'],
      'publisher': volumeInfo['publisher'],
      'publishedDate': volumeInfo['publishedDate'],
      'language': volumeInfo['language'],
      'previewLink': volumeInfo['previewLink'],
      'purchaseLink': purchaseLink,
      'coverUrl': coverUrl,
      'genre': genre,
      'isbn': isbn,
    };
  }

  /// Google Books cover resolver with ISBN + Amazon fallback.
  /// Priority:
  ///   1. Google Books imageLinks high-quality (extraLarge/large/medium)
  ///   2. Amazon ISBN10 cover (better hit rate for TR books than OL)
  ///   3. Open Library ISBN cover (often serves a 43-byte placeholder for TR
  ///      titles — listed last so it doesn't shadow Amazon)
  ///   4. Google Books imageLinks low-quality (small/thumbnail)
  ///   5. null
  String? _resolveGoogleBooksCover(
    Map<String, dynamic>? imageLinks,
    String? isbn,
  ) {
    String? highQuality;
    String? lowQuality;

    if (imageLinks != null) {
      if (imageLinks['extraLarge'] != null) {
        highQuality = imageLinks['extraLarge'];
      } else if (imageLinks['large'] != null) {
        highQuality = imageLinks['large'];
      } else if (imageLinks['medium'] != null) {
        highQuality = imageLinks['medium'];
      }

      if (imageLinks['small'] != null) {
        lowQuality = imageLinks['small'];
      } else if (imageLinks['thumbnail'] != null) {
        lowQuality = imageLinks['thumbnail'];
      } else if (imageLinks['smallThumbnail'] != null) {
        lowQuality = imageLinks['smallThumbnail'];
      }

      highQuality = _normalizeGoogleBooksCover(highQuality);
      lowQuality = _normalizeGoogleBooksCover(lowQuality);
    }

    if (highQuality != null) return highQuality;

    // ISBN-based fallbacks before falling back to low-quality Google thumbnail.
    if (isbn != null && isbn.isNotEmpty) {
      return _amazonCoverUrl(isbn) ??
          _olIsbnCoverUrl(isbn) ??
          lowQuality;
    }
    return lowQuality;
  }

  String? _normalizeGoogleBooksCover(String? url) {
    if (url == null) return null;
    var normalized = url;
    if (normalized.startsWith('http://')) {
      normalized = normalized.replaceFirst('http://', 'https://');
    }
    if (normalized.contains('books.google.com') ||
        normalized.contains('googleusercontent.com')) {
      normalized = normalized.replaceAll('&zoom=1', '&zoom=0');
      normalized = normalized.replaceAll('&edge=curl', '');
    }
    return normalized;
  }

  // ============ Open Library: books API (ISBN lookup) ============

  Future<Map<String, dynamic>?> _searchOpenLibraryBooksApi(String isbn) async {
    try {
      final url = Uri.parse(
        '$_openLibraryBooksUrl?bibkeys=ISBN:$isbn&jscmd=data&format=json',
      );
      debugPrint('[BookAPI] Open Library books: $isbn');

      final response = await http.get(url).timeout(_requestTimeout);
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final key = 'ISBN:$isbn';
      if (!data.containsKey(key)) return null;
      return _parseOpenLibraryBooksApi(data[key], isbn);
    } catch (e) {
      debugPrint('[BookAPI] Open Library books error: $e');
      return null;
    }
  }

  Map<String, dynamic> _parseOpenLibraryBooksApi(
    Map<String, dynamic> item,
    String isbn,
  ) {
    String author = '';
    if (item['authors'] != null) {
      author = (item['authors'] as List)
          .map((a) => a['name'] as String)
          .join(', ');
    }

    String? publisher;
    if (item['publishers'] != null && (item['publishers'] as List).isNotEmpty) {
      publisher = item['publishers'][0]['name'];
    }

    String? coverUrl;
    if (item['cover'] != null) {
      coverUrl = item['cover']['large'] ??
          item['cover']['medium'] ??
          item['cover']['small'];
    }
    // Fallback chain if cover block missing or returns nothing useful.
    coverUrl ??= _amazonCoverUrl(isbn) ?? _olIsbnCoverUrl(isbn);

    return {
      'title': item['title'] ?? '',
      'author': author,
      'description': null,
      'pageCount': item['number_of_pages'],
      'publisher': publisher,
      'publishedDate': item['publish_date'],
      'language': null,
      'previewLink': item['url'],
      'purchaseLink': 'https://www.amazon.com.tr/s?k=$isbn',
      'coverUrl': coverUrl,
      'genre': (item['subjects'] != null &&
              (item['subjects'] as List).isNotEmpty)
          ? (item['subjects'] as List).take(3).map((s) => s['name']).join(' / ')
          : 'Other',
      'isbn': isbn,
    };
  }

  // ============ Open Library: search.json ============

  /// Open Library's richer search endpoint. Accepts ISBN, title, author or any
  /// combination. Returns normalized book map or null.
  Future<Map<String, dynamic>?> _searchOpenLibrarySearch({
    String? isbn,
    String? title,
    String? author,
  }) async {
    try {
      final params = <String, String>{
        'limit': '1',
        'fields':
            'title,author_name,isbn,cover_i,key,publisher,first_publish_year,'
                'number_of_pages_median,subject,language',
      };
      if (isbn != null && isbn.isNotEmpty) params['isbn'] = isbn;
      if (title != null && title.isNotEmpty) params['title'] = title;
      if (author != null && author.isNotEmpty) params['author'] = author;
      if (params.length == 2) return null; // nothing to query on

      final url =
          Uri.parse(_openLibrarySearchUrl).replace(queryParameters: params);
      debugPrint('[BookAPI] Open Library search: $params');

      final response = await http.get(url).timeout(_requestTimeout);
      if (response.statusCode != 200) return null;

      final data = json.decode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
      final docs = data['docs'] as List?;
      if (docs == null || docs.isEmpty) return null;

      return _parseOpenLibrarySearchDoc(
        docs.first as Map<String, dynamic>,
        fallbackIsbn: isbn,
      );
    } catch (e) {
      debugPrint('[BookAPI] Open Library search error: $e');
      return null;
    }
  }

  Map<String, dynamic> _parseOpenLibrarySearchDoc(
    Map<String, dynamic> doc, {
    String? fallbackIsbn,
  }) {
    String author = '';
    if (doc['author_name'] != null) {
      author = (doc['author_name'] as List).join(', ');
    }

    // Pick the first ISBN13 if available, else any ISBN.
    String? isbn;
    if (doc['isbn'] != null) {
      final isbns = (doc['isbn'] as List).cast<String>();
      isbn = isbns.firstWhere(
        (i) => i.length == 13,
        orElse: () => isbns.isNotEmpty ? isbns.first : '',
      );
      if (isbn.isEmpty) isbn = null;
    }
    isbn ??= fallbackIsbn;

    // Cover: prefer cover_i → ISBN fallback → Amazon fallback.
    String? coverUrl;
    if (doc['cover_i'] is int) {
      coverUrl = _olCoverFromId(doc['cover_i'] as int);
    }
    coverUrl ??= _amazonCoverUrl(isbn) ?? _olIsbnCoverUrl(isbn);

    String? publisher;
    if (doc['publisher'] is List && (doc['publisher'] as List).isNotEmpty) {
      publisher = (doc['publisher'] as List).first as String;
    }

    String genre = 'Other';
    if (doc['subject'] is List && (doc['subject'] as List).isNotEmpty) {
      genre = (doc['subject'] as List).take(3).join(' / ');
    }

    String? language;
    if (doc['language'] is List && (doc['language'] as List).isNotEmpty) {
      language = (doc['language'] as List).first as String;
    }

    return {
      'title': doc['title'] ?? '',
      'author': author,
      'description': null,
      'pageCount': doc['number_of_pages_median'],
      'publisher': publisher,
      'publishedDate': doc['first_publish_year']?.toString(),
      'language': language,
      'previewLink':
          doc['key'] != null ? 'https://openlibrary.org${doc['key']}' : null,
      'purchaseLink': (isbn != null && isbn.isNotEmpty)
          ? 'https://www.amazon.com.tr/s?k=$isbn'
          : null,
      'coverUrl': coverUrl,
      'genre': genre,
      'isbn': isbn ?? '',
    };
  }

  // ============ D&R fallback (Cloud Function) ============

  /// Last-resort ISBN lookup via Cloud Function `lookupIsbnFallback`.
  /// The server scrapes D&R (dr.com.tr) JSON-LD structured data and caches
  /// successful lookups in Firestore (/books_cache/{isbn}) for 30 days.
  /// Used when Google Books and Open Library return nothing — typically for
  /// Turkish books missing from those public catalogs.
  Future<Map<String, dynamic>?> _searchDrFallback(String isbn) async {
    try {
      debugPrint('[BookAPI] D&R fallback (Cloud Function): $isbn');
      final result = await FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('lookupIsbnFallback')
          .call({'isbn': isbn});
      final data = result.data;
      if (data == null) return null;
      final map = (data as Map).cast<String, dynamic>();
      final title = (map['title'] as String?)?.trim();
      if (title == null || title.isEmpty) return null;
      final coverUrl = (map['coverUrl'] as String?) ??
          _amazonCoverUrl(isbn) ??
          _olIsbnCoverUrl(isbn);
      return {
        'title': title,
        'author': map['author'] ?? '',
        'description': map['description'],
        'pageCount': map['pageCount'],
        'publisher': map['publisher'],
        'publishedDate': map['publishedDate'],
        'language': map['language'],
        'previewLink': null,
        'purchaseLink': 'https://www.amazon.com.tr/s?k=$isbn',
        'coverUrl': coverUrl,
        'genre': 'Other',
        'isbn': isbn,
      };
    } catch (e) {
      debugPrint('[BookAPI] D&R fallback error: $e');
      return null;
    }
  }

  // ============ Result normalization ============

  /// Decodes HTML entities in user-visible string fields. Multiple sources
  /// (D&R JSON-LD, Open Library docs) ship entity-encoded apostrophes etc.
  /// verbatim — decode centrally so every parser benefits.
  @visibleForTesting
  Map<String, dynamic> normalizeBookMap(Map<String, dynamic> map) {
    const stringFields = ['title', 'author', 'publisher', 'description'];
    final out = Map<String, dynamic>.from(map);
    for (final field in stringFields) {
      final value = out[field];
      if (value is String) {
        out[field] = decodeHtmlEntities(value);
      }
    }
    return out;
  }

  /// Decodes the HTML entities upstream APIs sometimes ship verbatim
  /// (e.g. `O&#039;Farrell` instead of `O'Farrell`). Handles named entities
  /// (&amp;, &lt;, &gt;, &quot;, &apos;, &nbsp;) and numeric entities
  /// (decimal &#NN; and hex &#xHH;). Returns null if input is null/empty.
  @visibleForTesting
  String? decodeHtmlEntities(String? input) {
    if (input == null || input.isEmpty) return null;
    const named = {
      'amp': '&',
      'lt': '<',
      'gt': '>',
      'quot': '"',
      'apos': "'",
      'nbsp': ' ',
    };
    return input.replaceAllMapped(
      RegExp(r'&(#x([0-9a-fA-F]+)|#([0-9]+)|([a-zA-Z]+));'),
      (m) {
        if (m.group(2) != null) {
          final code = int.tryParse(m.group(2)!, radix: 16);
          if (code != null) return String.fromCharCode(code);
        } else if (m.group(3) != null) {
          final code = int.tryParse(m.group(3)!);
          if (code != null) return String.fromCharCode(code);
        } else if (m.group(4) != null) {
          final replacement = named[m.group(4)!.toLowerCase()];
          if (replacement != null) return replacement;
        }
        return m.group(0)!;
      },
    );
  }

  // ============ Cover URL helpers ============

  /// Open Library cover by ISBN. Returns null if ISBN is empty.
  String? _olIsbnCoverUrl(String? isbn) {
    if (isbn == null || isbn.isEmpty) return null;
    return 'https://covers.openlibrary.org/b/isbn/$isbn-L.jpg';
  }

  /// Open Library cover by cover_id (from search.json docs).
  String _olCoverFromId(int coverId) =>
      'https://covers.openlibrary.org/b/id/$coverId-L.jpg';

  /// Amazon's public cover CDN. Requires an ISBN10 — converts from ISBN13
  /// (978 prefix only; 979 prefix returns null since Amazon's pattern is
  /// keyed on legacy ISBN10).
  String? _amazonCoverUrl(String? isbn) {
    if (isbn == null || isbn.isEmpty) return null;
    String? isbn10;
    if (isbn.length == 10) {
      isbn10 = isbn.toUpperCase();
    } else if (isbn.length == 13 && isbn.startsWith('978')) {
      isbn10 = _isbn13ToIsbn10(isbn);
    }
    if (isbn10 == null) return null;
    return 'https://images-na.ssl-images-amazon.com/images/P/$isbn10.01._SCLZZZZZZZ_.jpg';
  }

  /// ISBN13 (978 prefix) → ISBN10. Returns null for malformed input or
  /// 979-prefixed ISBN13 (no legacy ISBN10 equivalent exists).
  String? _isbn13ToIsbn10(String isbn13) {
    if (isbn13.length != 13 || !isbn13.startsWith('978')) return null;
    final core = isbn13.substring(3, 12); // 9 digits
    if (!RegExp(r'^\d{9}$').hasMatch(core)) return null;

    var sum = 0;
    for (var i = 0; i < 9; i++) {
      sum += int.parse(core[i]) * (10 - i);
    }
    final mod = sum % 11;
    final checksum = (11 - mod) % 11;
    final checkChar = checksum == 10 ? 'X' : checksum.toString();
    return '$core$checkChar';
  }
}
