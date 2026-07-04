import 'package:cloud_firestore/cloud_firestore.dart';

class Library {
  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final String icon;
  final String color;
  final List<String> members;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  Library({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.icon = 'books',
    this.color = '#10B981', // Emerald default
    required this.members,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Library.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Library(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      icon: data['icon'] ?? 'books',
      color: data['color'] ?? '#10B981',
      members: List<String>.from(data['members'] ?? []),
      isDefault: data['isDefault'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'members': members,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
