import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingItem {
  final String id;
  final String ownerId;
  final String title;
  final String author;
  final String? coverUrl;
  final String genre;
  final String? subGenre;
  final String? isbn;
  final DateTime addedDate;
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

  ShoppingItem({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.author,
    this.coverUrl,
    required this.genre,
    this.subGenre,
    this.isbn,
    required this.addedDate,
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
  });

  factory ShoppingItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShoppingItem(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      coverUrl: data['coverUrl'],
      genre: data['genre'] ?? 'Diğer',
      subGenre: data['subGenre'],
      isbn: data['isbn'],
      addedDate: (data['addedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'genre': genre,
      'subGenre': subGenre,
      'isbn': isbn,
      'addedDate': Timestamp.fromDate(addedDate),
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

  /// Generate a Book-compatible map for moving to a library
  Map<String, dynamic> toBookMap(String libraryId) {
    return {
      'libraryId': libraryId,
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'genre': genre,
      'subGenre': subGenre,
      'isbn': isbn,
      'addedDate': Timestamp.fromDate(DateTime.now()),
      'ownerId': ownerId,
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
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
