import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_book_progress.dart';

/// Service for managing user-specific reading progress.
/// Progress is stored in /users/{userId}/book_progress/{bookId}
class UserProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _progressCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('book_progress');
  }

  /// Get progress for a specific book
  Stream<UserBookProgress?> getProgress(String bookId) {
    if (currentUserId == null) return Stream.value(null);

    return _progressCollection(currentUserId!).doc(bookId).snapshots().map((
      doc,
    ) {
      if (doc.exists) {
        return UserBookProgress.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Get progress for a specific book (one-time)
  Future<UserBookProgress?> getProgressOnce(String bookId) async {
    if (currentUserId == null) return null;

    final doc = await _progressCollection(currentUserId!).doc(bookId).get();
    if (doc.exists) {
      return UserBookProgress.fromFirestore(doc);
    }
    return null;
  }

  /// Update progress for a book
  Future<void> updateProgress({
    required String bookId,
    String? status,
    int? rating,
    String? userNotes,
    int? progressPercent,
    DateTime? startedAt,
    DateTime? completedAt,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final docRef = _progressCollection(currentUserId!).doc(bookId);
    final existingDoc = await docRef.get();

    final Map<String, dynamic> data = {
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (status != null) data['status'] = status;
    if (rating != null) data['rating'] = rating;
    if (userNotes != null) data['userNotes'] = userNotes;
    if (progressPercent != null) data['progressPercent'] = progressPercent;
    if (startedAt != null) data['startedAt'] = Timestamp.fromDate(startedAt);
    if (completedAt != null) {
      data['completedAt'] = Timestamp.fromDate(completedAt);
    }

    // Auto-set startedAt when status changes to 'reading'
    if (status == 'reading' && !existingDoc.exists) {
      data['startedAt'] = FieldValue.serverTimestamp();
    }

    // Auto-set completedAt when status changes to 'completed'
    if (status == 'completed') {
      data['completedAt'] = FieldValue.serverTimestamp();

      // Record activity for calendar - we need book title
      // Activity will be recorded by the caller with book info
    }

    // Record activity for 'reading' status
    // Activity will be recorded by the caller with book info

    if (existingDoc.exists) {
      await docRef.update(data);
    } else {
      // New progress entry
      data['status'] = status ?? 'toRead';
      data['rating'] = rating ?? 0;
      await docRef.set(data);
    }
  }

  /// Get all progress for current user
  Stream<List<UserBookProgress>> getAllProgress() {
    if (currentUserId == null) return Stream.value([]);

    return _progressCollection(currentUserId!).snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => UserBookProgress.fromFirestore(doc))
          .toList(),
    );
  }

  /// Get progress entries by status
  Stream<List<UserBookProgress>> getProgressByStatus(String status) {
    if (currentUserId == null) return Stream.value([]);

    return _progressCollection(currentUserId!)
        .where('status', isEqualTo: status)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserBookProgress.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get book IDs by status (for querying books)
  Future<List<String>> getBookIdsByStatus(String status) async {
    if (currentUserId == null) return [];

    final snapshot = await _progressCollection(
      currentUserId!,
    ).where('status', isEqualTo: status).get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }

  /// Get user stats (completed count, reading count, etc.)
  Future<Map<String, int>> getUserStats() async {
    if (currentUserId == null) {
      return {'toRead': 0, 'reading': 0, 'completed': 0};
    }

    final snapshot = await _progressCollection(currentUserId!).get();

    int toRead = 0;
    int reading = 0;
    int completed = 0;

    for (final doc in snapshot.docs) {
      final status = doc.data()['status'] as String? ?? 'toRead';
      switch (status) {
        case 'toRead':
          toRead++;
          break;
        case 'reading':
          reading++;
          break;
        case 'completed':
          completed++;
          break;
      }
    }

    return {
      'toRead': toRead,
      'reading': reading,
      'completed': completed,
      'total': toRead + reading + completed,
    };
  }

  /// Update status for multiple books at once
  Future<void> updateBulkStatus(List<String> bookIds, String status) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    if (bookIds.isEmpty) return;

    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();

    for (final bookId in bookIds) {
      final docRef = _progressCollection(currentUserId!).doc(bookId);

      final Map<String, dynamic> data = {'status': status, 'updatedAt': now};

      // Auto-set completedAt when status is 'completed'
      if (status == 'completed') {
        data['completedAt'] = now;
      }

      // We use set with merge to create or update
      batch.set(docRef, data, SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Delete progress for a book (when book is deleted)
  Future<void> deleteProgress(String bookId) async {
    if (currentUserId == null) return;
    await _progressCollection(currentUserId!).doc(bookId).delete();
  }

  /// Initialize progress from existing book data (for migration)
  Future<void> migrateFromBook({
    required String bookId,
    required String userId,
    required String status,
    required int rating,
    String? userNotes,
  }) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('book_progress')
        .doc(bookId);

    final existingDoc = await docRef.get();
    if (!existingDoc.exists) {
      await docRef.set({
        'status': status,
        'rating': rating,
        'userNotes': userNotes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
