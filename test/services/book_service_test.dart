import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liblibeapp/services/book_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late BookService service;

  const uid = 'user1';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: uid, email: 'a@b.com'),
    );
    service = BookService(firestore: firestore, auth: auth);
  });

  Future<void> seedBook({
    required String id,
    required String title,
    String author = 'Author',
    String? isbn,
    String owner = uid,
  }) async {
    await firestore.collection('books').doc(id).set({
      'libraryId': 'lib1',
      'title': title,
      'author': author,
      'isbn': isbn,
      'genre': 'Roman',
      'ownerId': owner,
    });
  }

  group('searchBooks', () {
    test('returns only the current user\'s books matching the query', () async {
      await seedBook(id: '1', title: 'Suç ve Ceza');
      await seedBook(id: '2', title: 'Sefiller');
      await seedBook(id: '3', title: 'Suçlu', owner: 'someone-else');

      final results = await service.searchBooks('suç');

      expect(results.map((b) => b.title), ['Suç ve Ceza']);
    });

    test('matches author and isbn case-insensitively', () async {
      await seedBook(id: '1', title: 'X', author: 'Orhan Pamuk');
      await seedBook(id: '2', title: 'Y', isbn: '9786051982304');

      expect((await service.searchBooks('PAMUK')).single.author, 'Orhan Pamuk');
      expect((await service.searchBooks('978605')).single.isbn,
          '9786051982304');
    });

    test('returns empty list when signed out', () async {
      final signedOut = BookService(
        firestore: firestore,
        auth: MockFirebaseAuth(signedIn: false),
      );
      await seedBook(id: '1', title: 'Suç ve Ceza');
      expect(await signedOut.searchBooks('suç'), isEmpty);
    });
  });

  group('addBook', () {
    setUp(() async {
      await firestore.collection('libraries').doc('lib1').set({
        'ownerId': uid,
        'name': 'My Library',
      });
    });

    test('writes a new book document owned by the current user', () async {
      final book = await service.addBook(
        libraryId: 'lib1',
        title: 'Yeni Kitap',
        author: 'Yazar',
      );

      final stored = await firestore.collection('books').doc(book.id).get();
      expect(stored.exists, isTrue);
      expect(stored.data()!['title'], 'Yeni Kitap');
      expect(stored.data()!['ownerId'], uid);
    });

    test('rejects duplicates with the same title and author', () async {
      await service.addBook(libraryId: 'lib1', title: 'Dup', author: 'Y');
      expect(
        () => service.addBook(libraryId: 'lib1', title: 'Dup', author: 'Y'),
        throwsA(isA<Exception>()),
      );
    });

    test('rejects adding to a library the user does not own', () async {
      await firestore.collection('libraries').doc('lib2').set({
        'ownerId': 'someone-else',
      });
      expect(
        () => service.addBook(libraryId: 'lib2', title: 'X', author: 'Y'),
        throwsA(isA<Exception>()),
      );
    });

    test('rejects when the library does not exist', () async {
      expect(
        () => service.addBook(libraryId: 'ghost', title: 'X', author: 'Y'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
