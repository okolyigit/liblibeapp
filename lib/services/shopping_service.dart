import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/shopping_item.dart';

class ShoppingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Add a new item to the shopping list
  Future<ShoppingItem> addItem({
    required String title,
    required String author,
    String? coverUrl,
    String genre = 'Diğer',
    String? subGenre,
    String? isbn,
    String? description,
    int? pageCount,
    String? publisher,
    String? publishedDate,
    String? language,
    String? previewLink,
    String? purchaseLink,
    List<String> categories = const [],
  }) async {
    if (currentUserId == null) throw Exception('Kullanıcı oturumu bulunamadı');

    final docRef = _firestore.collection('shopping_items').doc();
    final now = DateTime.now();

    final item = ShoppingItem(
      id: docRef.id,
      ownerId: currentUserId!,
      title: title,
      author: author,
      coverUrl: coverUrl,
      genre: genre,
      subGenre: subGenre,
      isbn: isbn,
      addedDate: now,
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

    await docRef.set(item.toMap());
    return item;
  }

  /// Stream all shopping items for the current user
  Stream<List<ShoppingItem>> getItems() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('shopping_items')
        .where('ownerId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => ShoppingItem.fromFirestore(doc))
              .toList();
          items.sort((a, b) => b.addedDate.compareTo(a.addedDate));
          return items;
        });
  }

  /// Get a single shopping item
  Future<ShoppingItem?> getItem(String itemId) async {
    final doc =
        await _firestore.collection('shopping_items').doc(itemId).get();
    if (doc.exists) {
      return ShoppingItem.fromFirestore(doc);
    }
    return null;
  }

  /// Delete a shopping item
  Future<void> deleteItem(String itemId) async {
    await _firestore.collection('shopping_items').doc(itemId).delete();
  }

  /// Move a shopping item to a library (create book + delete item)
  Future<void> moveToLibrary(String itemId, String libraryId) async {
    if (currentUserId == null) throw Exception('Kullanıcı oturumu bulunamadı');

    final itemDoc =
        await _firestore.collection('shopping_items').doc(itemId).get();
    if (!itemDoc.exists) throw Exception('Öğe bulunamadı');

    final item = ShoppingItem.fromFirestore(itemDoc);

    // Verify user owns this item
    if (item.ownerId != currentUserId) {
      throw Exception('Bu öğeyi taşıma yetkiniz yok');
    }

    // Verify library exists and user is a member
    final libraryDoc =
        await _firestore.collection('libraries').doc(libraryId).get();
    if (!libraryDoc.exists) throw Exception('Kütüphane bulunamadı');

    final libraryData = libraryDoc.data()!;
    if (libraryData['ownerId'] != currentUserId) {
      throw Exception('Bu kütüphaneye kitap ekleme yetkiniz yok');
    }

    // Check for duplicates in the target library
    final existingBooksQuery = await _firestore
        .collection('books')
        .where('libraryId', isEqualTo: libraryId)
        .where('title', isEqualTo: item.title)
        .where('author', isEqualTo: item.author)
        .get();

    if (existingBooksQuery.docs.isNotEmpty) {
      throw Exception('Bu kitap bu kütüphanede zaten mevcut');
    }

    // Batch: add to books + delete from shopping_items
    final batch = _firestore.batch();

    final bookRef = _firestore.collection('books').doc();
    batch.set(bookRef, item.toBookMap(libraryId));

    batch.delete(_firestore.collection('shopping_items').doc(itemId));

    await batch.commit();

    debugPrint('Shopping item $itemId moved to library $libraryId');
  }

  /// Get count of shopping items
  Future<int> getItemCount() async {
    if (currentUserId == null) return 0;

    final snapshot = await _firestore
        .collection('shopping_items')
        .where('ownerId', isEqualTo: currentUserId)
        .count()
        .get();

    return snapshot.count ?? 0;
  }
}
