import 'package:cloud_firestore/cloud_firestore.dart';

/// User-specific reading progress for a book.
/// Stored in /users/{userId}/book_progress/{bookId}
class UserBookProgress {
  final String bookId;
  final int rating; // 0-5
  final String? userNotes;
  final int? progressPercent;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime updatedAt;

  UserBookProgress({
    required this.bookId,
    this.rating = 0,
    this.userNotes,
    this.progressPercent,
    this.startedAt,
    this.completedAt,
    required this.updatedAt,
  });

  factory UserBookProgress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserBookProgress(
      bookId: doc.id,
      rating: data['rating'] ?? 0,
      userNotes: data['userNotes'],
      progressPercent: data['progressPercent'],
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rating': rating,
      'userNotes': userNotes,
      'progressPercent': progressPercent,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserBookProgress copyWith({
    int? rating,
    String? userNotes,
    int? progressPercent,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return UserBookProgress(
      bookId: bookId,
      rating: rating ?? this.rating,
      userNotes: userNotes ?? this.userNotes,
      progressPercent: progressPercent ?? this.progressPercent,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Create a default progress for a new book
  factory UserBookProgress.defaultProgress(String bookId) {
    return UserBookProgress(
      bookId: bookId,
      rating: 0,
      updatedAt: DateTime.now(),
    );
  }
}
