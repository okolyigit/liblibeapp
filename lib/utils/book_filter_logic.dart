import '../models/book.dart';

/// Filter state for book filtering across the app
class BookFilterState {
  final List<String> genres; // Roman, Distopya, Klasik, etc. - multi-select
  final List<int> years; // 2024, 2025, etc. - multi-select
  final List<int> ratings; // 1-5 - multi-select
  final String sortBy; // title, author, date, rating
  final String searchQuery;
  final List<String> selectedCategories;

  const BookFilterState({
    this.genres = const [],
    this.years = const [],
    this.ratings = const [],
    this.sortBy = 'title',
    this.searchQuery = '',
    this.selectedCategories = const [],
  });

  BookFilterState copyWith({
    List<String>? genres,
    List<int>? years,
    List<int>? ratings,
    String? sortBy,
    String? searchQuery,
    List<String>? selectedCategories,
    bool clearGenres = false,
    bool clearYears = false,
    bool clearRatings = false,
    bool clearCategories = false,
  }) {
    return BookFilterState(
      genres: clearGenres ? const [] : (genres ?? this.genres),
      years: clearYears ? const [] : (years ?? this.years),
      ratings: clearRatings ? const [] : (ratings ?? this.ratings),
      sortBy: sortBy ?? this.sortBy,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategories: clearCategories
          ? const []
          : (selectedCategories ?? this.selectedCategories),
    );
  }

  /// Check if any filters are active (besides default)
  bool get hasActiveFilters =>
      genres.isNotEmpty ||
      years.isNotEmpty ||
      ratings.isNotEmpty ||
      selectedCategories.isNotEmpty ||
      sortBy != 'title';

  /// Reset all filters to default
  BookFilterState reset() => const BookFilterState();
}

/// Apply filters to a list of books
List<Book> applyFilters(List<Book> books, BookFilterState filter) {
  List<Book> result = List.from(books);

  // Filter by genres (multi-select - match any)
  if (filter.genres.isNotEmpty) {
    result = result.where((b) => filter.genres.contains(b.genre)).toList();
  }

  // Filter by years (multi-select - match any)
  if (filter.years.isNotEmpty) {
    result = result.where((b) {
      final date = _parsePublishedDate(b.publishedDate);
      return date != null && filter.years.contains(date.year);
    }).toList();
  }

  // Filter by ratings (multi-select - match any)
  if (filter.ratings.isNotEmpty) {
    result = result
        .where((b) => filter.ratings.contains(b.rating.round()))
        .toList();
  }

  // Filter by selected categories
  if (filter.selectedCategories.isNotEmpty) {
    result = result.where((b) {
      return filter.selectedCategories.every(
        (cat) => b.categories.contains(cat),
      );
    }).toList();
  }

  // Filter by search query
  if (filter.searchQuery.isNotEmpty) {
    final query = filter.searchQuery.toLowerCase();
    result = result
        .where(
          (b) =>
              b.title.toLowerCase().contains(query) ||
              b.author.toLowerCase().contains(query) ||
              (b.isbn != null && b.isbn!.toLowerCase().contains(query)) ||
              b.categories.any((c) => c.toLowerCase().contains(query)),
        )
        .toList();
  }

  // Sort
  switch (filter.sortBy) {
    case 'title_asc':
    case 'title': // backward compatibility
      result.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
      break;
    case 'title_desc':
      result.sort(
        (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
      );
      break;
    case 'author_asc':
    case 'author': // backward compatibility
      result.sort(
        (a, b) => a.author.toLowerCase().compareTo(b.author.toLowerCase()),
      );
      break;
    case 'author_desc':
      result.sort(
        (a, b) => b.author.toLowerCase().compareTo(a.author.toLowerCase()),
      );
      break;
    case 'added_desc':
    case 'date': // backward compatibility
      result.sort((a, b) => b.addedDate.compareTo(a.addedDate));
      break;
    case 'added_asc':
      result.sort((a, b) => a.addedDate.compareTo(b.addedDate));
      break;
    case 'publish_desc': // Newest -> Oldest
      result.sort((a, b) {
        final dateA = _parsePublishedDate(a.publishedDate);
        final dateB = _parsePublishedDate(b.publishedDate);
        // Nulls last
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateB.compareTo(dateA);
      });
      break;
    case 'publish_asc': // Oldest -> Newest
      result.sort((a, b) {
        final dateA = _parsePublishedDate(a.publishedDate);
        final dateB = _parsePublishedDate(b.publishedDate);
        // Nulls last
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateA.compareTo(dateB);
      });
      break;
    case 'rating':
      result.sort((a, b) => b.rating.compareTo(a.rating));
      break;
  }

  return result;
}

DateTime? _parsePublishedDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return null;
  // Try YYYY-MM-DD
  try {
    return DateTime.parse(dateStr);
  } catch (_) {}
  // Try YYYY
  try {
    if (dateStr.length == 4) {
      return DateTime(int.parse(dateStr), 1, 1);
    }
  } catch (_) {}
  return null;
}

/// Get sort label in Turkish
String getSortLabel(String sort) {
  switch (sort) {
    case 'title_asc':
      return 'Başlık (A-Z)';
    case 'title_desc':
      return 'Başlık (Z-A)';
    case 'author_asc':
      return 'Yazar (A-Z)';
    case 'author_desc':
      return 'Yazar (Z-A)';
    case 'added_asc':
      return 'Eklenme (Eski-Yeni)';
    case 'added_desc':
    case 'date':
      return 'Eklenme (Yeni-Eski)';
    case 'publish_asc':
      return 'Basım (Eski-Yeni)';
    case 'publish_desc':
      return 'Basım (Yeni-Eski)';
    case 'rating':
      return 'Puan';
    default:
      return 'Varsayılan';
  }
}

/// Get all available genres from books
List<String> getAvailableGenres(List<Book> books) {
  return books.map((b) => b.genre).toSet().toList()..sort();
}

/// Get all available years from books (using Published Date)
List<int> getAvailableYears(List<Book> books) {
  final years = <int>{};
  for (var b in books) {
    final date = _parsePublishedDate(b.publishedDate);
    if (date != null) {
      years.add(date.year);
    }
  }
  return years.toList()..sort((a, b) => b.compareTo(a));
}

/// Get all available categories from books
List<String> getAvailableCategories(List<Book> books) {
  final allCats = <String>{};
  for (var book in books) {
    allCats.addAll(book.categories);
  }
  return allCats.toList()..sort();
}
