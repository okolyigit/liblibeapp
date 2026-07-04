import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Migration service to move reading progress from books to user_progress collection
class MigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Migrate all books' status/rating/userNotes to user_progress collection
  /// Returns a map with 'migrated' and 'skipped' counts
  Future<Map<String, int>> migrateUserProgress({
    Function(String)? onProgress,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    int migrated = 0;
    int skipped = 0;

    try {
      // Get all books owned by current user
      final booksSnapshot = await _firestore
          .collection('books')
          .where('ownerId', isEqualTo: currentUserId)
          .get();

      onProgress?.call('${booksSnapshot.docs.length} kitap bulundu...');

      for (final bookDoc in booksSnapshot.docs) {
        final bookData = bookDoc.data();
        final bookId = bookDoc.id;

        // Check if progress already exists
        final existingProgress = await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('book_progress')
            .doc(bookId)
            .get();

        if (existingProgress.exists) {
          skipped++;
          continue;
        }

        // Extract user-specific data from book
        final status = bookData['status'] as String? ?? 'toRead';
        final rating = bookData['rating'] as int? ?? 0;
        final userNotes = bookData['userNotes'] as String?;

        // Only migrate if there's meaningful data
        if (status != 'toRead' ||
            rating > 0 ||
            (userNotes != null && userNotes.isNotEmpty)) {
          await _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('book_progress')
              .doc(bookId)
              .set({
                'status': status,
                'rating': rating,
                'userNotes': userNotes,
                'updatedAt': FieldValue.serverTimestamp(),
                'migratedAt': FieldValue.serverTimestamp(),
              });

          migrated++;
          onProgress?.call('${bookData['title']} taşındı');
        } else {
          skipped++;
        }
      }

      debugPrint('[OK] Migration complete: $migrated migrated, $skipped skipped');
      return {'migrated': migrated, 'skipped': skipped};
    } catch (e) {
      debugPrint('âŒ Migration error: $e');
      rethrow;
    }
  }

  /// Check if migration is needed (any books have status/rating/userNotes but no progress)
  Future<bool> isMigrationNeeded() async {
    if (currentUserId == null) return false;

    try {
      // Check if user has any books with status other than 'toRead'
      final booksWithStatus = await _firestore
          .collection('books')
          .where('ownerId', isEqualTo: currentUserId)
          .where('status', whereIn: ['reading', 'completed'])
          .limit(1)
          .get();

      if (booksWithStatus.docs.isEmpty) return false;

      // Check if user already has progress documents
      final progressDocs = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('book_progress')
          .limit(1)
          .get();

      // Migration needed if there are books with status but no progress docs
      return progressDocs.docs.isEmpty;
    } catch (e) {
      debugPrint('Error checking migration status: $e');
      return false;
    }
  }

  /// Get migration statistics without actually migrating
  Future<Map<String, int>> getMigrationStats() async {
    if (currentUserId == null) {
      return {'needsMigration': 0, 'alreadyMigrated': 0};
    }

    try {
      final booksSnapshot = await _firestore
          .collection('books')
          .where('ownerId', isEqualTo: currentUserId)
          .get();

      int needsMigration = 0;
      int alreadyMigrated = 0;

      for (final bookDoc in booksSnapshot.docs) {
        final bookData = bookDoc.data();
        final status = bookData['status'] as String? ?? 'toRead';
        final rating = bookData['rating'] as int? ?? 0;
        final userNotes = bookData['userNotes'] as String?;

        // Check if there's meaningful data to migrate
        if (status != 'toRead' ||
            rating > 0 ||
            (userNotes != null && userNotes.isNotEmpty)) {
          final existingProgress = await _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('book_progress')
              .doc(bookDoc.id)
              .get();

          if (existingProgress.exists) {
            alreadyMigrated++;
          } else {
            needsMigration++;
          }
        }
      }

      return {
        'needsMigration': needsMigration,
        'alreadyMigrated': alreadyMigrated,
        'total': booksSnapshot.docs.length,
      };
    } catch (e) {
      debugPrint('Error getting migration stats: $e');
      return {'needsMigration': 0, 'alreadyMigrated': 0, 'total': 0};
    }
  }
}
