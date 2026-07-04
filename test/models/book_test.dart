import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liblibeapp/models/book.dart';

void main() {
  group('Book.toMap', () {
    test('serialises core fields and converts dates to Timestamps', () {
      final book = Book(
        id: 'ignored-on-write',
        libraryId: 'lib1',
        title: 'Suç ve Ceza',
        author: 'Dostoyevski',
        genre: 'Roman',
        isbn: '9786051982304',
        addedDate: DateTime(2024, 3, 1),
        ownerId: 'user1',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 2, 1),
        categories: const ['Klasik'],
      );

      final map = book.toMap();

      expect(map['title'], 'Suç ve Ceza');
      expect(map['libraryId'], 'lib1');
      expect(map['ownerId'], 'user1');
      expect(map['categories'], ['Klasik']);
      expect(map['addedDate'], isA<Timestamp>());
      expect((map['addedDate'] as Timestamp).toDate(), DateTime(2024, 3, 1));
      // Deprecated user-specific fields must not be written back.
      expect(map.containsKey('rating'), isFalse);
      expect(map.containsKey('userNotes'), isFalse);
    });
  });

  group('Book.fromFirestore', () {
    late FakeFirebaseFirestore firestore;

    setUp(() => firestore = FakeFirebaseFirestore());

    Future<Book> readBack(Map<String, dynamic> data) async {
      await firestore.collection('books').doc('b1').set(data);
      final doc = await firestore.collection('books').doc('b1').get();
      return Book.fromFirestore(doc);
    }

    test('round-trips a fully populated document', () async {
      final original = Book(
        id: 'b1',
        libraryId: 'lib1',
        title: 'Kar',
        author: 'Orhan Pamuk',
        genre: 'Roman',
        isbn: '123',
        addedDate: DateTime(2024, 3, 1),
        ownerId: 'user1',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 2, 1),
        categories: const ['Klasik', 'Distopya'],
        pageCount: 432,
        publisher: 'YKY',
        publishedDate: '2002',
      );

      final book = await readBack(original.toMap());

      expect(book.id, 'b1');
      expect(book.title, 'Kar');
      expect(book.author, 'Orhan Pamuk');
      expect(book.genre, 'Roman');
      expect(book.categories, ['Klasik', 'Distopya']);
      expect(book.pageCount, 432);
      expect(book.publisher, 'YKY');
      expect(book.addedDate, DateTime(2024, 3, 1));
    });

    test('applies defaults for missing fields', () async {
      final book = await readBack({'title': 'Yalnızca başlık'});

      expect(book.title, 'Yalnızca başlık');
      expect(book.author, '');
      expect(book.genre, 'Other');
      expect(book.libraryId, '');
      expect(book.categories, isEmpty);
      expect(book.rating, 0);
      expect(book.isbn, isNull);
    });

    test('falls back to legacy addedBy when ownerId is absent', () async {
      final book = await readBack({'title': 'X', 'addedBy': 'legacy-user'});
      expect(book.ownerId, 'legacy-user');
    });
  });
}
