import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/book.dart';
import 'book_api_service.dart';
import 'cover_storage_service.dart';

class BookService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Production callers use the default constructor (real Firebase singletons).
  /// Tests can inject fakes (e.g. fake_cloud_firestore, firebase_auth_mocks).
  BookService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Search books
  Future<List<Book>> searchBooks(String query) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('books')
          .where('ownerId', isEqualTo: user.uid)
          .get();

      final books = snapshot.docs
          .map((doc) => Book.fromFirestore(doc))
          .toList();
      final loweredQuery = query.toLowerCase();

      return books.where((book) {
        return book.title.toLowerCase().contains(loweredQuery) ||
            book.author.toLowerCase().contains(loweredQuery) ||
            (book.isbn != null && book.isbn!.toLowerCase().contains(loweredQuery));
      }).toList();
    } catch (e) {
      debugPrint('Error searching books: $e');
      return [];
    }
  }

  // Add a book to a library (without user-specific fields)
  Future<Book> addBook({
    required String libraryId,
    required String title,
    required String author,
    String? coverUrl,
    String genre = 'Diğer',
    String? subGenre,
    String? isbn,
    // API fields
    String? description,
    int? pageCount,
    String? publisher,
    String? publishedDate,
    String? language,
    String? previewLink,
    String? purchaseLink,
    List<String> categories = const [],
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    // Verify that the user owns the library they're adding to
    final libraryDoc = await _firestore
        .collection('libraries')
        .doc(libraryId)
        .get();
    if (!libraryDoc.exists) {
      throw Exception('Kütüphane bulunamadı.');
    }
    if (libraryDoc.data()?['ownerId'] != currentUserId) {
      throw Exception('Bu kütüphaneye kitap ekleme yetkiniz yok.');
    }

    // Check for duplicates in the same library
    final existingBooksQuery = await _firestore
        .collection('books')
        .where('libraryId', isEqualTo: libraryId)
        .where('title', isEqualTo: title)
        .where('author', isEqualTo: author)
        .get();

    if (existingBooksQuery.docs.isNotEmpty) {
      throw Exception('Bu kitap bu kütüphanede zaten mevcut.');
    }

    final docRef = _firestore.collection('books').doc();
    final now = DateTime.now();

    final book = Book(
      id: docRef.id,
      libraryId: libraryId,
      title: title,
      author: author,
      coverUrl: coverUrl,
      genre: genre,
      subGenre: subGenre,
      isbn: isbn,
      addedDate: now,
      ownerId: currentUserId!,
      createdAt: now,
      updatedAt: now,
      description: description,
      pageCount: pageCount,
      publisher: publisher,
      publishedDate: publishedDate,
      language: language,
      previewLink: previewLink,
      purchaseLink: purchaseLink,
      categories: categories,
    );

    await docRef.set(book.toMap());
    return book;
  }

  // Get books for a specific library (no status filtering - that's now user-specific)
  Stream<List<Book>> getLibraryBooks(String libraryId) {
    return _firestore
        .collection('books')
        .where('libraryId', isEqualTo: libraryId)
        .orderBy('addedDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();
        });
  }

  // Get books by IDs
  Future<List<Book>> getBooksByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    // Firestore 'in' query supports up to 10 items.
    // So we need to batch requests if there are more than 10.
    final List<Book> books = [];

    // Split into chunks of 10
    for (var i = 0; i < ids.length; i += 10) {
      final end = (i + 10 < ids.length) ? i + 10 : ids.length;
      final chunk = ids.sublist(i, end);

      final snapshot = await _firestore
          .collection('books')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      books.addAll(
        snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList(),
      );
    }

    return books;
  }

  // Get a single book
  Future<Book?> getBook(String bookId) async {
    final doc = await _firestore.collection('books').doc(bookId).get();
    if (doc.exists) {
      return Book.fromFirestore(doc);
    }
    return null;
  }

  // Update book data
  // Note: status/rating/userNotes are ALLOWED for backwards compatibility
  // The new system uses UserProgressService, but old system needs book updates too
  Future<void> updateBook(String bookId, Map<String, dynamic> data) async {
    await _firestore.collection('books').doc(bookId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get all books owned by current user
  /// Get books recently added across all accessible libraries
  Stream<List<Book>> getRecentlyAddedBooks(int limit) {
    if (currentUserId == null) return Stream.value([]);

    final controller = StreamController<List<Book>>.broadcast();
    StreamSubscription? libSub;
    StreamSubscription? bookSub;

    libSub = _firestore
        .collection('libraries')
        .where('members', arrayContains: currentUserId)
        .snapshots()
        .listen((libSnapshot) {
          final libraryIds = libSnapshot.docs.map((d) => d.id).toList();
          bookSub?.cancel();

          if (libraryIds.isEmpty) {
            if (!controller.isClosed) controller.add([]);
            return;
          }

          // Limit to 30 libraries for whereIn query
          final idsToQuery = libraryIds.take(30).toList();

          bookSub = _firestore
              .collection('books')
              .where('libraryId', whereIn: idsToQuery)
              .orderBy('addedDate', descending: true)
              .limit(limit)
              .snapshots()
              .listen((booksSnapshot) {
                final books = booksSnapshot.docs
                    .map((d) => Book.fromFirestore(d))
                    .toList();
                if (!controller.isClosed) controller.add(books);
              }, onError: (e) => controller.addError(e));
        }, onError: (e) => controller.addError(e));

    controller.onCancel = () {
      libSub?.cancel();
      bookSub?.cancel();
    };

    return controller.stream;
  }

  // Get total book count for user
  Future<int> getUserBookCount() async {
    if (currentUserId == null) return 0;

    final snapshot = await _firestore
        .collection('books')
        .where('ownerId', isEqualTo: currentUserId)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  // Delete book and cleanup references
  Future<void> deleteBook(String bookId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final batch = _firestore.batch();

    // 1. Delete the book document
    final bookRef = _firestore.collection('books').doc(bookId);
    batch.delete(bookRef);

    // 2. Remove from current user's lists only (we can only update our own lists)
    final listsSnapshot = await _firestore
        .collection('lists')
        .where('ownerId', isEqualTo: currentUserId)
        .where('bookIds', arrayContains: bookId)
        .get();

    for (var doc in listsSnapshot.docs) {
      batch.update(doc.reference, {
        'bookIds': FieldValue.arrayRemove([bookId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // 3. Delete current user's like for this book only
    final likesSnapshot = await _firestore
        .collection('likes')
        .where('userId', isEqualTo: currentUserId)
        .where('bookId', isEqualTo: bookId)
        .get();

    for (var doc in likesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 4. Delete current user's progress for this book
    final progressRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('book_progress')
        .doc(bookId);
    batch.delete(progressRef);

    await batch.commit();

    // Best-effort: remove any uploaded gallery cover. Covers live at
    // covers/{ownerId}/{bookId}.jpg and only the owner may delete them
    // (storage rules) — which is the common delete path. No-op if the book
    // used an external cover URL.
    await CoverStorageService().deleteCover(currentUserId!, bookId);
  }

  /// Get books that user is currently reading (includes shared library books)
  Stream<List<Book>> getRecentlyUpdatedBooks(int limit) {
    if (currentUserId == null) return Stream.value([]);

    final controller = StreamController<List<Book>>.broadcast();
    StreamSubscription? progressSub;
    StreamSubscription? booksSub;

    progressSub = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('book_progress')
        .where('status', isEqualTo: 'reading')
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .listen((progressSnapshot) {
          final bookIds = progressSnapshot.docs.map((d) => d.id).toList();
          booksSub?.cancel();

          if (bookIds.isEmpty) {
            if (!controller.isClosed) controller.add([]);
            return;
          }

          final idsToQuery = bookIds.take(30).toList();

          booksSub = _firestore
              .collection('books')
              .where(FieldPath.documentId, whereIn: idsToQuery)
              .snapshots()
              .listen((booksSnapshot) {
                final booksMap = {
                  for (var b in booksSnapshot.docs.map(
                    (d) => Book.fromFirestore(d),
                  ))
                    b.id: b,
                };

                final sortedBooks = bookIds
                    .map((id) => booksMap[id])
                    .whereType<Book>()
                    .toList();

                if (!controller.isClosed) controller.add(sortedBooks);
              }, onError: (e) => controller.addError(e));
        }, onError: (e) => controller.addError(e));

    controller.onCancel = () {
      progressSub?.cancel();
      booksSub?.cancel();
    };

    return controller.stream;
  }

  /// Get user book stats including shared library books
  /// Counts: total accessible books, reading from progress, completed from progress
  Stream<Map<String, int>> getUserBookStats() {
    if (currentUserId == null) {
      return Stream.value({'total': 0, 'reading': 0, 'read': 0});
    }

    final userId = currentUserId!;
    final controller = StreamController<Map<String, int>>.broadcast();

    // Helper to calculate and emit stats
    Future<void> emitStats() async {
      if (controller.isClosed) return;
      try {
        final userId = currentUserId!;

        // 1. Get libraries and count books in one go (whereIn batch)
        final libSnapshot = await _firestore
            .collection('libraries')
            .where('members', arrayContains: userId)
            .get();

        final libraryIds = libSnapshot.docs.map((d) => d.id).toList();

        int totalBooks = 0;
        if (libraryIds.isNotEmpty) {
          // Batch count across all libraries (up to 30)
          final countSnapshot = await _firestore
              .collection('books')
              .where('libraryId', whereIn: libraryIds.take(30).toList())
              .count()
              .get();
          totalBooks = countSnapshot.count ?? 0;
        }

        // 2. Count reading/completed from user's book_progress
        int reading = 0;
        int completed = 0;

        final progressSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('book_progress')
            .get();

        for (final doc in progressSnapshot.docs) {
          final status = doc.data()['status'] as String? ?? 'toRead';
          if (status == 'reading') reading++;
          if (status == 'completed') completed++;
        }

        if (!controller.isClosed) {
          controller.add({
            'total': totalBooks,
            'reading': reading,
            'read': completed,
          });
        }
      } catch (e) {
        debugPrint('Error calculating stats: $e');
        if (!controller.isClosed) controller.addError(e);
      }
    }

    // Listen to changes in both libraries AND book_progress
    final libSubscription = _firestore
        .collection('libraries')
        .where('members', arrayContains: userId)
        .snapshots()
        .listen((_) => emitStats());

    final progressSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('book_progress')
        .snapshots()
        .listen((_) => emitStats());

    // Also listen to OWNED books to update total count on add/delete
    final booksSubscription = _firestore
        .collection('books')
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .listen((_) => emitStats());

    controller.onCancel = () {
      libSubscription.cancel();
      progressSubscription.cancel();
      booksSubscription.cancel();
    };

    // Initial trigger
    emitStats();

    return controller.stream;
  }

  // ========================================================================
  // DATA MANAGEMENT (RESET & ENRICH)
  // ========================================================================

  /// Permanently delete ALL user data (Books, Lists, Likes, Activities, Progress)
  /// This is a destructive operation!
  Future<void> deleteAllUserData() async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final userId = currentUserId!;
    const batchSize = 500;

    // Helper to delete query results in batches
    Future<void> deleteQueryBatch(Query query) async {
      final snapshot = await query.limit(batchSize).get();
      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Recurse if there might be more
      if (snapshot.docs.length == batchSize) {
        await deleteQueryBatch(query);
      }
    }

    // 1. Delete Books
    await deleteQueryBatch(
      _firestore.collection('books').where('ownerId', isEqualTo: userId),
    );

    // 2. Delete Lists
    await deleteQueryBatch(
      _firestore.collection('lists').where('ownerId', isEqualTo: userId),
    );

    // 3. Delete Likes (Favorites)
    await deleteQueryBatch(
      _firestore.collection('likes').where('userId', isEqualTo: userId),
    );

    // 4. Delete Reading Activities
    await deleteQueryBatch(
      _firestore
          .collection('reading_activities')
          .where('userId', isEqualTo: userId),
    );

    // 4b. Delete Shopping Items
    await deleteQueryBatch(
      _firestore
          .collection('shopping_items')
          .where('ownerId', isEqualTo: userId),
    );

    // 5. Delete or reset Libraries owned by user
    final libSnapshot = await _firestore
        .collection('libraries')
        .where('ownerId', isEqualTo: userId)
        .get();

    final libBatch = _firestore.batch();
    for (final doc in libSnapshot.docs) {
      final data = doc.data();
      if (data['isDefault'] == true) {
        // For default library: clear members (shares) but keep the library
        libBatch.update(doc.reference, {
          'members': [userId], // Reset to only owner
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Delete non-default libraries
        libBatch.delete(doc.reference);
      }
    }
    await libBatch.commit();

    // 6. Delete User Book Progress (Subcollection)
    // Note: Collection Group queries can't easily delete, but we know the path here:
    // /users/{userId}/book_progress/{bookId}
    final progressRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('book_progress');
    await deleteQueryBatch(progressRef);

    // 7. Delete Notifications
    final notifRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications');
    await deleteQueryBatch(notifRef);

    debugPrint('All user data deleted for user: $userId');
  }

  /// Enrich book data using ISBNs and Google Books API
  /// Returns a stream of progress status messages or updates
  Future<void> enrichBookData({
    required Function(int current, int total, String status) onProgress,
  }) async {
    if (currentUserId == null) return;

    // 1. Get all user books
    final snapshot = await _firestore
        .collection('books')
        .where('ownerId', isEqualTo: currentUserId)
        .get();

    final allBooks = snapshot.docs;
    final total = allBooks.length;
    int current = 0;
    int updatedCount = 0;
    int failedCount = 0;

    final apiService = BookApiService();

    for (final doc in allBooks) {
      current++;
      final book = Book.fromFirestore(doc);

      // Update progress text
      onProgress(current, total, 'İnceleniyor: ${book.title}');

      // We need an ISBN to be sure about the book match
      if (book.isbn == null || book.isbn!.isEmpty) {
        continue;
      }

      try {
        // Search by ISBN
        final details = await apiService.searchByIsbn(book.isbn!);

        if (details != null) {
          final Map<String, dynamic> updates = {};

          // 1. Cover URL — replace if missing OR known-broken pattern.
          // The legacy fallback chain emitted OL ISBN URLs that always 200
          // but return a 43-byte placeholder; rewrite those. Also catches
          // old Google Books low-res `&zoom=1` thumbnails.
          final String? currentCover = book.coverUrl;
          final bool hasNoCover =
              currentCover == null || currentCover.isEmpty;
          final bool isOlPlaceholder = currentCover != null &&
              currentCover.contains('covers.openlibrary.org/b/isbn/');
          final bool isLowRes =
              currentCover != null && currentCover.contains('&zoom=1');
          final newCover = details['coverUrl'] as String?;
          if ((hasNoCover || isOlPlaceholder || isLowRes) &&
              newCover != null &&
              newCover.isNotEmpty) {
            updates['coverUrl'] = newCover;
          }

          if ((book.description == null || book.description!.isEmpty) &&
              details['description'] != null) {
            updates['description'] = details['description'];
          }
          if ((book.pageCount == null || book.pageCount == 0) &&
              details['pageCount'] != null) {
            updates['pageCount'] = details['pageCount'];
          }
          if ((book.publisher == null || book.publisher!.isEmpty) &&
              details['publisher'] != null) {
            updates['publisher'] = details['publisher'];
          }
          if ((book.publishedDate == null || book.publishedDate!.isEmpty) &&
              details['publishedDate'] != null) {
            updates['publishedDate'] = details['publishedDate'];
          }
          if ((book.language == null || book.language!.isEmpty) &&
              details['language'] != null) {
            updates['language'] = details['language'];
          }

          if (updates.isNotEmpty) {
            await updateBook(book.id, updates);
            onProgress(current, total, 'Güncellendi: ${book.title}');
            updatedCount++;
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      } catch (e) {
        debugPrint('Error enriching book ${book.title}: $e');
        failedCount++;
      }
    }

    onProgress(
      total,
      total,
      'Tamamlandı: $updatedCount güncellendi'
      '${failedCount > 0 ? ", $failedCount hata" : ""}',
    );
  }
}
