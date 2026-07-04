// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Liblibe';

  @override
  String get actionCancel => 'İptal';

  @override
  String get actionOk => 'Tamam';

  @override
  String get actionDelete => 'Sil';

  @override
  String get actionSave => 'Kaydet';

  @override
  String get actionRetry => 'Tekrar dene';

  @override
  String get genericErrorTitle => 'Bir şeyler ters gitti';

  @override
  String get offline => 'İnternet bağlantısı yok';

  @override
  String get validationRequiredField => 'Boş bırakılamaz';

  @override
  String get validationEmailRequired => 'E-posta adresi gerekli';

  @override
  String get validationEmailInvalid => 'Geçerli bir e-posta adresi girin';

  @override
  String get navHome => 'Ana Sayfa';

  @override
  String get navBooks => 'Kitaplar';

  @override
  String get navLibraries => 'Kütüphaneler';

  @override
  String get navProfile => 'Profil';
}
