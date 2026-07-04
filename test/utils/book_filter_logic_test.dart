import 'package:flutter_test/flutter_test.dart';
import 'package:liblibeapp/models/book.dart';
import 'package:liblibeapp/utils/book_filter_logic.dart';

/// Builds a [Book] with sensible defaults so each test only sets the fields
/// it actually cares about.
Book makeBook({
  String id = 'id',
  String title = 'Title',
  String author = 'Author',
  String genre = 'Roman',
  String? isbn,
  String? publishedDate,
  int rating = 0,
  List<String> categories = const [],
  DateTime? addedDate,
}) {
  final now = DateTime(2024, 1, 1);
  return Book(
    id: id,
    libraryId: 'lib',
    title: title,
    author: author,
    genre: genre,
    isbn: isbn,
    publishedDate: publishedDate,
    rating: rating,
    categories: categories,
    addedDate: addedDate ?? now,
    ownerId: 'owner',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('applyFilters - genre', () {
    test('keeps only books matching any selected genre', () {
      final books = [
        makeBook(id: '1', genre: 'Roman'),
        makeBook(id: '2', genre: 'Bilim Kurgu'),
        makeBook(id: '3', genre: 'Tarih'),
      ];
      final result = applyFilters(
        books,
        const BookFilterState(genres: ['Roman', 'Tarih']),
      );
      expect(result.map((b) => b.id), ['1', '3']);
    });

    test('empty genre filter keeps everything', () {
      final books = [makeBook(id: '1'), makeBook(id: '2')];
      expect(applyFilters(books, const BookFilterState()).length, 2);
    });
  });

  group('applyFilters - year (publishedDate parsing)', () {
    test('matches full ISO dates and bare years', () {
      final books = [
        makeBook(id: 'iso', publishedDate: '2020-05-01'),
        makeBook(id: 'year', publishedDate: '2021'),
        makeBook(id: 'other', publishedDate: '1999'),
        makeBook(id: 'null', publishedDate: null),
      ];
      final result = applyFilters(
        books,
        const BookFilterState(years: [2020, 2021]),
      );
      expect(result.map((b) => b.id), ['iso', 'year']);
    });
  });

  group('applyFilters - rating', () {
    test('rounds rating before matching', () {
      final books = [
        makeBook(id: 'r5', rating: 5),
        makeBook(id: 'r3', rating: 3),
        makeBook(id: 'r0', rating: 0),
      ];
      final result = applyFilters(books, const BookFilterState(ratings: [5]));
      expect(result.map((b) => b.id), ['r5']);
    });
  });

  group('applyFilters - categories', () {
    test('requires every selected category to be present', () {
      final books = [
        makeBook(id: 'both', categories: ['Fiction', 'Classic']),
        makeBook(id: 'one', categories: ['Fiction']),
      ];
      final result = applyFilters(
        books,
        const BookFilterState(selectedCategories: ['Fiction', 'Classic']),
      );
      expect(result.map((b) => b.id), ['both']);
    });
  });

  group('applyFilters - search query', () {
    test('matches title, author, isbn and categories case-insensitively', () {
      final books = [
        makeBook(id: 'title', title: 'Suç ve Ceza'),
        makeBook(id: 'author', author: 'Orhan Pamuk'),
        makeBook(id: 'isbn', isbn: '9786051982304'),
        makeBook(id: 'cat', categories: ['Distopya']),
        makeBook(id: 'none', title: 'Zzz'),
      ];
      expect(
        applyFilters(books, const BookFilterState(searchQuery: 'suç'))
            .map((b) => b.id),
        ['title'],
      );
      expect(
        applyFilters(books, const BookFilterState(searchQuery: 'pamuk'))
            .map((b) => b.id),
        ['author'],
      );
      expect(
        applyFilters(books, const BookFilterState(searchQuery: '978605'))
            .map((b) => b.id),
        ['isbn'],
      );
      expect(
        applyFilters(books, const BookFilterState(searchQuery: 'distopya'))
            .map((b) => b.id),
        ['cat'],
      );
    });
  });

  group('applyFilters - sorting', () {
    test('title_asc / title_desc and backward-compatible "title"', () {
      final books = [
        makeBook(id: 'b', title: 'Bbb'),
        makeBook(id: 'a', title: 'Aaa'),
        makeBook(id: 'c', title: 'Ccc'),
      ];
      expect(
        applyFilters(books, const BookFilterState(sortBy: 'title_asc'))
            .map((b) => b.id),
        ['a', 'b', 'c'],
      );
      expect(
        applyFilters(books, const BookFilterState(sortBy: 'title_desc'))
            .map((b) => b.id),
        ['c', 'b', 'a'],
      );
      expect(
        applyFilters(books, const BookFilterState(sortBy: 'title'))
            .map((b) => b.id),
        ['a', 'b', 'c'],
      );
    });

    test('publish_desc puts nulls last', () {
      final books = [
        makeBook(id: 'old', publishedDate: '2000'),
        makeBook(id: 'new', publishedDate: '2020'),
        makeBook(id: 'null', publishedDate: null),
      ];
      expect(
        applyFilters(books, const BookFilterState(sortBy: 'publish_desc'))
            .map((b) => b.id),
        ['new', 'old', 'null'],
      );
    });

    test('added_desc sorts by addedDate newest first', () {
      final books = [
        makeBook(id: 'old', addedDate: DateTime(2020, 1, 1)),
        makeBook(id: 'new', addedDate: DateTime(2024, 1, 1)),
      ];
      expect(
        applyFilters(books, const BookFilterState(sortBy: 'added_desc'))
            .map((b) => b.id),
        ['new', 'old'],
      );
    });
  });

  group('applyFilters - does not mutate input', () {
    test('original list order is preserved', () {
      final books = [
        makeBook(id: 'b', title: 'Bbb'),
        makeBook(id: 'a', title: 'Aaa'),
      ];
      applyFilters(books, const BookFilterState(sortBy: 'title_asc'));
      expect(books.map((b) => b.id), ['b', 'a']);
    });
  });

  group('BookFilterState', () {
    test('hasActiveFilters reflects non-default state', () {
      expect(const BookFilterState().hasActiveFilters, isFalse);
      expect(const BookFilterState(genres: ['Roman']).hasActiveFilters, isTrue);
      expect(
        const BookFilterState(sortBy: 'rating').hasActiveFilters,
        isTrue,
      );
    });

    test('reset returns defaults', () {
      const state = BookFilterState(genres: ['Roman'], sortBy: 'rating');
      expect(state.reset().hasActiveFilters, isFalse);
    });

    test('copyWith clear flags wipe collections', () {
      const state = BookFilterState(genres: ['Roman'], years: [2020]);
      final cleared = state.copyWith(clearGenres: true);
      expect(cleared.genres, isEmpty);
      expect(cleared.years, [2020]);
    });
  });

  group('aggregation helpers', () {
    final books = [
      makeBook(genre: 'Roman', publishedDate: '2020', categories: ['A', 'B']),
      makeBook(genre: 'Tarih', publishedDate: '2021', categories: ['B', 'C']),
    ];

    test('getAvailableGenres is sorted and unique', () {
      expect(getAvailableGenres(books), ['Roman', 'Tarih']);
    });

    test('getAvailableYears is sorted descending', () {
      expect(getAvailableYears(books), [2021, 2020]);
    });

    test('getAvailableCategories is sorted and unique', () {
      expect(getAvailableCategories(books), ['A', 'B', 'C']);
    });

    test('getSortLabel maps known and unknown keys', () {
      expect(getSortLabel('title_asc'), 'Başlık (A-Z)');
      expect(getSortLabel('rating'), 'Puan');
      expect(getSortLabel('unknown'), 'Varsayılan');
    });
  });
}
