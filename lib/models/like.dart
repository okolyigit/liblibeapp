import 'package:cloud_firestore/cloud_firestore.dart';

class Like {
  final String id;
  final String userId;
  final String bookId;
  final DateTime createdAt;

  Like({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.createdAt,
  });

  factory Like.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Like(
      id: doc.id,
      userId: data['userId'] ?? '',
      bookId: data['bookId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'bookId': bookId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
