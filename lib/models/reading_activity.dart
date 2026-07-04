import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a reading activity entry for a user.
/// Each entry logs a date when the user interacted with a book.
class ReadingActivity {
  final String id;
  final String userId;
  final String bookId;
  final String bookTitle;
  final String
  activityType; // 'started_reading', 'completed', 'progress_update'
  final DateTime activityDate;
  final DateTime createdAt;

  ReadingActivity({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.bookTitle,
    required this.activityType,
    required this.activityDate,
    required this.createdAt,
  });

  factory ReadingActivity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReadingActivity(
      id: doc.id,
      userId: data['userId'] ?? '',
      bookId: data['bookId'] ?? '',
      bookTitle: data['bookTitle'] ?? '',
      activityType: data['activityType'] ?? 'progress_update',
      activityDate:
          (data['activityDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'activityType': activityType,
      'activityDate': Timestamp.fromDate(activityDate),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
