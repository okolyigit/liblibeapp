import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LikeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Get the user's favorites list ID (simplified query without composite index)
  Future<String?> _getFavoritesListId() async {
    if (currentUserId == null) return null;

    // Simple query - only filter by ownerId, then check isDefault client-side
    final snapshot = await _firestore
        .collection('lists')
        .where('ownerId', isEqualTo: currentUserId)
        .get();

    // Find the default list client-side
    for (var doc in snapshot.docs) {
      if (doc.data()['isDefault'] == true) {
        return doc.id;
      }
    }
    return null;
  }

  /// Toggle like - adds/removes book from Beğenilenler list
  Future<bool> toggleLike(String bookId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final favoritesId = await _getFavoritesListId();
    if (favoritesId == null) throw Exception('Beğenilenler listesi bulunamadı');

    final listDoc = await _firestore.collection('lists').doc(favoritesId).get();
    final bookIds = List<String>.from(listDoc.data()?['bookIds'] ?? []);

    if (bookIds.contains(bookId)) {
      // Remove from favorites
      await _firestore.collection('lists').doc(favoritesId).update({
        'bookIds': FieldValue.arrayRemove([bookId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return false; // Not liked anymore
    } else {
      // Add to favorites
      await _firestore.collection('lists').doc(favoritesId).update({
        'bookIds': FieldValue.arrayUnion([bookId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true; // Liked
    }
  }

  /// Check if book is liked (in Beğenilenler list)
  Stream<bool> isBookLiked(String bookId) {
    if (currentUserId == null) return Stream.value(false);

    // Simple query - filter client-side for isDefault
    return _firestore
        .collection('lists')
        .where('ownerId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
          // Find default list
          for (var doc in snapshot.docs) {
            if (doc.data()['isDefault'] == true) {
              final bookIds = List<String>.from(doc.data()['bookIds'] ?? []);
              return bookIds.contains(bookId);
            }
          }
          return false;
        });
  }

  /// Get all liked book IDs
  Stream<List<String>> getLikedBookIds() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('lists')
        .where('ownerId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
          // Find default list
          for (var doc in snapshot.docs) {
            if (doc.data()['isDefault'] == true) {
              return List<String>.from(doc.data()['bookIds'] ?? []);
            }
          }
          return <String>[];
        });
  }
}
