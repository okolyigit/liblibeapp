import 'package:flutter_test/flutter_test.dart';
import 'package:liblibeapp/services/book_api_service.dart';

void main() {
  final service = BookApiService();

  group('decodeHtmlEntities', () {
    test('returns null for null or empty input', () {
      expect(service.decodeHtmlEntities(null), isNull);
      expect(service.decodeHtmlEntities(''), isNull);
    });

    test('decodes the numeric apostrophe regression case', () {
      // The real-world D&R bug: "Maggie O&#039;Farrell" rendered literally.
      expect(
        service.decodeHtmlEntities('Maggie O&#039;Farrell'),
        "Maggie O'Farrell",
      );
    });

    test('decodes named entities', () {
      expect(
        service.decodeHtmlEntities('Tom &amp; Jerry &lt;3 &quot;hi&quot;'),
        'Tom & Jerry <3 "hi"',
      );
      expect(service.decodeHtmlEntities('a&nbsp;b'), 'a b');
    });

    test('decodes decimal and hex numeric entities', () {
      expect(service.decodeHtmlEntities('&#65;&#66;'), 'AB');
      expect(service.decodeHtmlEntities('&#x41;&#x42;'), 'AB');
    });

    test('leaves unknown entities untouched', () {
      expect(service.decodeHtmlEntities('&unknown;'), '&unknown;');
    });

    test('is idempotent on already-decoded text', () {
      const decoded = "Maggie O'Farrell & Co";
      expect(service.decodeHtmlEntities(decoded), decoded);
    });
  });

  group('normalizeBookMap', () {
    test('decodes only the user-visible string fields', () {
      final result = service.normalizeBookMap({
        'title': 'Tom &amp; Jerry',
        'author': 'O&#039;Farrell',
        'publisher': 'A &lt; B',
        'description': '&quot;quoted&quot;',
        'isbn': '978&amp;123', // untouched: not in the decode set
        'pageCount': 432, // untouched: non-string
      });

      expect(result['title'], 'Tom & Jerry');
      expect(result['author'], "O'Farrell");
      expect(result['publisher'], 'A < B');
      expect(result['description'], '"quoted"');
      expect(result['isbn'], '978&amp;123');
      expect(result['pageCount'], 432);
    });

    test('does not mutate the input map', () {
      final input = {'title': 'Tom &amp; Jerry'};
      service.normalizeBookMap(input);
      expect(input['title'], 'Tom &amp; Jerry');
    });
  });
}
