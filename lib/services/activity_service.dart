import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/reading_activity.dart';

/// Service for managing reading activity tracking.
class ActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Log a reading activity for the current user.
  Future<void> logActivity({
    required String bookId,
    required String bookTitle,
    required String activityType,
  }) async {
    if (currentUserId == null) return;

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Check if there's already an activity for this book today
      final existingQuery = await _firestore
          .collection('reading_activities')
          .where('userId', isEqualTo: currentUserId)
          .where('bookId', isEqualTo: bookId)
          .where('activityDate', isEqualTo: Timestamp.fromDate(today))
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        // Update existing activity type if needed
        await existingQuery.docs.first.reference.update({
          'activityType': activityType,
        });
        debugPrint('[Activity] Updated existing activity for $bookTitle');
      } else {
        // Create new activity
        await _firestore.collection('reading_activities').add({
          'userId': currentUserId,
          'bookId': bookId,
          'bookTitle': bookTitle,
          'activityType': activityType,
          'activityDate': Timestamp.fromDate(today),
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint('[Activity] Logged new activity for $bookTitle on $today');
      }
    } catch (e) {
      debugPrint('âŒ Error logging activity: $e');
    }
  }

  /// Get all reading days for the current user in a given month.
  Stream<Set<DateTime>> getReadingDaysForMonth(int year, int month) {
    if (currentUserId == null) return Stream.value({});

    // Get all activities for user and filter by month client-side
    // This avoids needing a composite index on userId + activityDate
    return _firestore
        .collection('reading_activities')
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
          final days = <DateTime>{};
          for (final doc in snapshot.docs) {
            try {
              final activity = ReadingActivity.fromFirestore(doc);
              // Filter to only include activities from the requested month
              if (activity.activityDate.year == year &&
                  activity.activityDate.month == month) {
                days.add(
                  DateTime(
                    activity.activityDate.year,
                    activity.activityDate.month,
                    activity.activityDate.day,
                  ),
                );
              }
            } catch (e) {
              debugPrint('Error parsing activity: $e');
            }
          }
          debugPrint('[Activity] Found ${days.length} reading days for $month/$year');
          return days;
        });
  }

  /// Get all activities for a specific book.
  Stream<List<ReadingActivity>> getBookActivities(String bookId) {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('reading_activities')
        .where('userId', isEqualTo: currentUserId)
        .where('bookId', isEqualTo: bookId)
        .orderBy('activityDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ReadingActivity.fromFirestore(doc))
              .toList();
        });
  }
}
