import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/reading_list.dart';

class ListService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Search lists
  Future<List<ReadingList>> searchLists(String query) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('lists')
          .where('ownerId', isEqualTo: user.uid)
          .get();

      final lists = snapshot.docs
          .map((doc) => ReadingList.fromFirestore(doc))
          .toList();
      final loweredQuery = query.toLowerCase();

      return lists.where((list) {
        return list.name.toLowerCase().contains(loweredQuery);
      }).toList();
    } catch (e) {
      debugPrint('Error searching lists: $e');
      return [];
    }
  }

  // Create a new list
  Future<ReadingList> createList({
    required String name,
    String? description,
    bool isPublic = false,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final docRef = _firestore.collection('lists').doc();
    final now = DateTime.now();

    final list = ReadingList(
      id: docRef.id,
      ownerId: currentUserId!,
      name: name,
      description: description,
      bookIds: [],
      members: [],
      isPublic: isPublic,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(list.toMap());
    return list;
  }

  // Get user's lists (owned + shared)
  Stream<List<ReadingList>> getUserLists() {
    if (currentUserId == null) {
      debugPrint('[Lists] getUserLists: currentUserId is null');
      return Stream.value([]);
    }

    debugPrint('[Lists] getUserLists: Fetching lists for user $currentUserId');

    return _firestore
        .collection('lists')
        .where('ownerId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
          debugPrint('[Lists] getUserLists: Got ${snapshot.docs.length} documents');
          for (var doc in snapshot.docs) {
            debugPrint('   - ${doc.id}: ${doc.data()}');
          }
          final lists = snapshot.docs
              .map((doc) => ReadingList.fromFirestore(doc))
              .toList();
          // Sort client-side: default lists first, then by updatedAt
          lists.sort((a, b) {
            if (a.isDefault && !b.isDefault) return -1;
            if (!a.isDefault && b.isDefault) return 1;
            return b.updatedAt.compareTo(a.updatedAt);
          });
          return lists;
        });
  }

  // Get public lists
  Stream<List<ReadingList>> getPublicLists() {
    return _firestore
        .collection('lists')
        .where('isPublic', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ReadingList.fromFirestore(doc))
              .toList();
        });
  }

  // Add book to list
  Future<void> addBookToList(String listId, String bookId) async {
    await _firestore.collection('lists').doc(listId).update({
      'bookIds': FieldValue.arrayUnion([bookId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Remove book from list
  Future<void> removeBookFromList(String listId, String bookId) async {
    await _firestore.collection('lists').doc(listId).update({
      'bookIds': FieldValue.arrayRemove([bookId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Remove multiple books from list
  Future<void> removeBooksFromList(String listId, List<String> bookIds) async {
    if (bookIds.isEmpty) return;

    await _firestore.collection('lists').doc(listId).update({
      'bookIds': FieldValue.arrayRemove(bookIds),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete list (but not default lists like Favorites)
  Future<void> deleteList(String listId) async {
    // Check if it's a default list first
    final doc = await _firestore.collection('lists').doc(listId).get();
    if (doc.exists && doc.data()?['isDefault'] == true) {
      throw Exception('Varsayılan listeler silinemez');
    }
    await _firestore.collection('lists').doc(listId).delete();
  }

  // Update list
  Future<void> updateList(
    String listId, {
    String? name,
    String? description,
    bool? isPublic,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (isPublic != null) updates['isPublic'] = isPublic;

    await _firestore.collection('lists').doc(listId).update(updates);
  }
}
