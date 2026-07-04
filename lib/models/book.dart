import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  final String id;
  final String libraryId;
  final String title;
  final String author;
  final String? coverUrl;
  final String genre;
  final String? subGenre;
  final String? isbn;
  final DateTime addedDate;
  final String ownerId; // Owner of the book (userId who added it)
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> categories;

  // Additional fields from Google Books API
  final String? description;
  final int? pageCount;
  final String? publisher;
  final String? publishedDate;
  final String? language;
  final String? previewLink;
  final String? purchaseLink;

  // DEPRECATED: These fields are kept for backwards compatibility during migration.
  // New code should use UserProgressService to get/set user-specific data.
  // These values come from Firestore (old data) but should NOT be written back.
  final int rating; // 1-5 - DEPRECATED
  final String? userNotes; // DEPRECATED

  Book({
    required this.id,
    required this.libraryId,
    required this.title,
    required this.author,
    this.coverUrl,
    required this.genre,
    this.subGenre,
    this.isbn,
    required this.addedDate,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.pageCount,
    this.publisher,
    this.publishedDate,
    this.language,
    this.previewLink,
    this.purchaseLink,
    this.categories = const [],
    // Deprecated fields with defaults
    this.rating = 0,
    this.userNotes,
  });

  factory Book.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Book(
      id: doc.id,
      libraryId: data['libraryId'] ?? '',
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      coverUrl: data['coverUrl'],
      genre: data['genre'] ?? 'Other',
      subGenre: data['subGenre'],
      isbn: data['isbn'],
      addedDate: (data['addedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ownerId: data['ownerId'] ?? data['addedBy'] ?? '', // Backward compatible
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: data['description'],
      pageCount: data['pageCount'],
      publisher: data['publisher'],
      publishedDate: data['publishedDate'],
      language: data['language'],
      previewLink: data['previewLink'],
      purchaseLink: data['purchaseLink'],
      categories: List<String>.from(data['categories'] ?? []),
      // Read deprecated fields from Firestore for backwards compatibility
      rating: data['rating'] ?? 0,
      userNotes: data['userNotes'],
    );
  }

  Map<String, dynamic> toMap() {
    // Note: status, rating, userNotes are NOT included here
    // They should be managed by UserProgressService
    return {
      'libraryId': libraryId,
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'genre': genre,
      'subGenre': subGenre,
      'isbn': isbn,
      'addedDate': Timestamp.fromDate(addedDate),
      'ownerId': ownerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'description': description,
      'pageCount': pageCount,
      'publisher': publisher,
      'publishedDate': publishedDate,
      'language': language,
      'previewLink': previewLink,
      'purchaseLink': purchaseLink,
      'categories': categories,
    };
  }
}
