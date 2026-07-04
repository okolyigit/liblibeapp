// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Liblibe';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionOk => 'OK';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionSave => 'Save';

  @override
  String get actionRetry => 'Retry';

  @override
  String get genericErrorTitle => 'Something went wrong';

  @override
  String get offline => 'No internet connection';

  @override
  String get validationRequiredField => 'This field cannot be empty';

  @override
  String get validationEmailRequired => 'E-mail address is required';

  @override
  String get validationEmailInvalid => 'Enter a valid e-mail address';

  @override
  String get navHome => 'Home';

  @override
  String get navBooks => 'Books';

  @override
  String get navLibraries => 'Libraries';

  @override
  String get navProfile => 'Profile';
}
