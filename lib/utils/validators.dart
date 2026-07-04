/// Reusable, UI-agnostic input validators.
///
/// Each `validate*` method returns a Turkish error string when the value is
/// invalid, or `null` when it is acceptable — matching Flutter's
/// `FormFieldValidator<String>` contract so they can be used directly as
/// `validator:` callbacks.
class Validators {
  Validators._();

  // Pragmatic RFC-5322-ish pattern: something@something.tld with no spaces.
  static final RegExp _email = RegExp(
    r'^[\w.!#$%&’*+/=?`{|}~^-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$',
  );

  /// Validates an e-mail address. Empty is treated as invalid (required).
  static String? validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'E-posta adresi gerekli';
    if (!_email.hasMatch(v)) return 'Geçerli bir e-posta adresi girin';
    return null;
  }

  /// Validates a password against a minimum length (default 6).
  static String? validatePassword(String? value, {int minLength = 6}) {
    final v = value ?? '';
    if (v.isEmpty) return 'Şifre gerekli';
    if (v.length < minLength) return 'Şifre en az $minLength karakter olmalı';
    return null;
  }

  /// Validates a 10- or 13-digit ISBN (digits, with an optional trailing X for
  /// ISBN-10). Returns null for empty input since ISBN is usually optional —
  /// callers that require it should check emptiness separately.
  static String? validateIsbn(String? value, {bool required = false}) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return required ? 'ISBN gerekli' : null;
    final cleaned = raw.replaceAll(RegExp(r'[\s-]'), '');
    final isIsbn13 = RegExp(r'^\d{13}$').hasMatch(cleaned);
    final isIsbn10 = RegExp(r'^\d{9}[\dXx]$').hasMatch(cleaned);
    if (!isIsbn13 && !isIsbn10) {
      return 'ISBN 10 veya 13 haneli olmalı';
    }
    return null;
  }

  /// Validates an optional http(s) URL (e.g. a purchase link). Empty is
  /// allowed; non-empty must be a well-formed absolute http/https URL.
  static String? validateOptionalUrl(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    final uri = Uri.tryParse(v);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        !uri.hasAuthority) {
      return 'Geçerli bir bağlantı girin (http/https)';
    }
    return null;
  }
}
