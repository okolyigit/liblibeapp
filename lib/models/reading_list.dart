import 'package:cloud_firestore/cloud_firestore.dart';

class ReadingList {
  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final String? coverUrl;
  final String? icon; // Icon name (e.g., 'heart', 'star', 'books')
  final String? color; // Color hex (e.g., '#EF4444')
  final List<String> bookIds;
  final List<String> members;
  final bool isPublic;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get bookCount => bookIds.length;

  ReadingList({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.coverUrl,
    this.icon,
    this.color,
    required this.bookIds,
    required this.members,
    this.isPublic = false,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReadingList.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReadingList(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      coverUrl: data['coverUrl'],
      icon: data['icon'],
      color: data['color'],
      bookIds: List<String>.from(data['bookIds'] ?? []),
      members: List<String>.from(data['members'] ?? []),
      isPublic: data['isPublic'] ?? false,
      isDefault: data['isDefault'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'coverUrl': coverUrl,
      'icon': icon,
      'color': color,
      'bookIds': bookIds,
      'members': members,
      'isPublic': isPublic,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
