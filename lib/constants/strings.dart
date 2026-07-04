/// Centralised, reusable UI strings.
///
/// This is the staging point for internationalisation (i18n). Today these are
/// Turkish literals collected from across the app to remove duplication; when
/// `flutter_localizations` + `.arb` files are introduced (see plan Faz 5), the
/// getters/helpers here become the natural seam to swap for `AppLocalizations`
/// lookups without touching every call site again.
class AppStrings {
  AppStrings._();

  // === Form validation ===
  /// Shown when a required form field is left empty.
  static const String emptyField = 'Boş bırakılamaz';

  // === Common dialog / action labels ===
  static const String cancel = 'İptal';
  static const String ok = 'Tamam';
  static const String delete = 'Sil';
  static const String save = 'Kaydet';

  // === Errors ===
  /// Generic "something went wrong" message with the underlying detail.
  /// Replaces the repeated `'Hata: $e'` literal scattered across screens.
  static String genericError(Object error) => 'Hata: $error';
}
