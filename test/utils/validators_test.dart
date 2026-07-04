import 'package:flutter_test/flutter_test.dart';
import 'package:liblibeapp/utils/validators.dart';

void main() {
  group('validateEmail', () {
    test('accepts well-formed addresses', () {
      expect(Validators.validateEmail('a@b.com'), isNull);
      expect(Validators.validateEmail('  user.name@sub.domain.co  '), isNull);
    });

    test('rejects empty and malformed addresses', () {
      expect(Validators.validateEmail(''), isNotNull);
      expect(Validators.validateEmail(null), isNotNull);
      expect(Validators.validateEmail('plainaddress'), isNotNull);
      expect(Validators.validateEmail('a@b'), isNotNull);
      expect(Validators.validateEmail('a @b.com'), isNotNull);
    });
  });

  group('validatePassword', () {
    test('enforces minimum length', () {
      expect(Validators.validatePassword('123456'), isNull);
      expect(Validators.validatePassword('12345'), isNotNull);
      expect(Validators.validatePassword(''), isNotNull);
    });
  });

  group('validateIsbn', () {
    test('accepts valid ISBN-10 and ISBN-13 with separators', () {
      expect(Validators.validateIsbn('9786051982304'), isNull);
      expect(Validators.validateIsbn('978-605-198-230-4'), isNull);
      expect(Validators.validateIsbn('0306406152'), isNull);
      expect(Validators.validateIsbn('097522980X'), isNull);
    });

    test('empty is allowed unless required', () {
      expect(Validators.validateIsbn(''), isNull);
      expect(Validators.validateIsbn('', required: true), isNotNull);
    });

    test('rejects wrong lengths', () {
      expect(Validators.validateIsbn('123'), isNotNull);
      expect(Validators.validateIsbn('12345678901234'), isNotNull);
    });
  });

  group('validateOptionalUrl', () {
    test('allows empty', () {
      expect(Validators.validateOptionalUrl(''), isNull);
    });

    test('accepts http and https URLs', () {
      expect(Validators.validateOptionalUrl('https://dr.com.tr/x'), isNull);
      expect(Validators.validateOptionalUrl('http://a.b'), isNull);
    });

    test('rejects non-http schemes and garbage', () {
      expect(Validators.validateOptionalUrl('ftp://a.b'), isNotNull);
      expect(Validators.validateOptionalUrl('not a url'), isNotNull);
    });
  });
}
