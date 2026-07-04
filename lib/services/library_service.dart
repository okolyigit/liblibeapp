import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/library.dart';
import 'book_service.dart';

class LibraryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Create a new library
  Future<Library> createLibrary({
    required String name,
    String? description,
    String icon = 'books',
    String color = '#10B981',
    bool isDefault = false,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final docRef = _firestore.collection('libraries').doc();
    final now = DateTime.now();

    final library = Library(
      id: docRef.id,
      ownerId: currentUserId!,
      name: name,
      description: description,
      icon: icon,
      color: color,
      members: [currentUserId!],
      isDefault: isDefault,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(library.toMap());
    return library;
  }

  // Get all libraries for current user (owned or shared)
  Stream<List<Library>> getUserLibraries() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('libraries')
        .where('members', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
          final libraries = snapshot.docs
              .map((doc) => Library.fromFirestore(doc))
              .toList();
          // Sort client-side by createdAt ascending
          libraries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return libraries;
        });
  }

  // Get a specific library
  Future<Library?> getLibrary(String libraryId) async {
    final doc = await _firestore.collection('libraries').doc(libraryId).get();
    if (doc.exists) {
      return Library.fromFirestore(doc);
    }
    return null;
  }

  // Update library
  Future<void> updateLibrary(
    String libraryId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection('libraries').doc(libraryId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete library and all its books
  Future<void> deleteLibrary(String libraryId) async {
    final bookService = BookService();
    // 1. Delete all books in this library using the specialized service
    final booksQuery = await _firestore
        .collection('books')
        .where('libraryId', isEqualTo: libraryId)
        .get();

    for (final doc in booksQuery.docs) {
      await bookService.deleteBook(doc.id);
    }

    // 2. Delete the library document
    await _firestore.collection('libraries').doc(libraryId).delete();
  }

  // Add member to library
  Future<void> addMember(String libraryId, String userId) async {
    await _firestore.collection('libraries').doc(libraryId).update({
      'members': FieldValue.arrayUnion([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Remove member from library
  Future<void> removeMember(String libraryId, String userId) async {
    await _firestore.collection('libraries').doc(libraryId).update({
      'members': FieldValue.arrayRemove([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
