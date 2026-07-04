import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing user preferences locally
class PreferencesService {
  static const String _booksViewModeKey = 'books_view_mode';
  static const String _listsViewModeKey = 'lists_view_mode';

  static PreferencesService? _instance;
  static SharedPreferences? _prefs;

  PreferencesService._();

  static Future<PreferencesService> getInstance() async {
    if (_instance == null) {
      _instance = PreferencesService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  /// Get the books view mode (true = grid, false = list)
  bool getBooksViewMode() {
    return _prefs?.getBool(_booksViewModeKey) ?? true; // Default to grid
  }

  /// Set the books view mode
  Future<void> setBooksViewMode(bool isGridView) async {
    await _prefs?.setBool(_booksViewModeKey, isGridView);
  }

  /// Get the lists view mode (true = grid, false = list)
  bool getListsViewMode() {
    return _prefs?.getBool(_listsViewModeKey) ?? true; // Default to grid
  }

  /// Set the lists view mode
  Future<void> setListsViewMode(bool isGridView) async {
    await _prefs?.setBool(_listsViewModeKey, isGridView);
  }

  // Theme Preferences
  static const String _themeModeKey = 'theme_mode';
  static const String _blackThemeKey = 'black_theme';

  /// Get the saved theme mode (0 = system, 1 = light, 2 = dark)
  int getThemeMode() {
    return _prefs?.getInt(_themeModeKey) ?? 0; // Default to system
  }

  /// Set the theme mode
  Future<void> setThemeMode(int themeMode) async {
    await _prefs?.setInt(_themeModeKey, themeMode);
  }

  /// Get if black theme is enabled
  bool getBlackTheme() {
    return _prefs?.getBool(_blackThemeKey) ?? false;
  }

  /// Set black theme preference
  Future<void> setBlackTheme(bool isBlack) async {
    await _prefs?.setBool(_blackThemeKey, isBlack);
  }

  // Language Preferences
  static const String _languageKey = 'language_code';

  /// Get the saved language code (e.g. 'tr', 'en'). Defaults to Turkish.
  String getLanguageCode() {
    return _prefs?.getString(_languageKey) ?? 'tr';
  }

  /// Set the preferred language code.
  Future<void> setLanguageCode(String code) async {
    await _prefs?.setString(_languageKey, code);
  }

  // Onboarding Preferences
  static const String _hasSeenOnboardingKey = 'has_seen_onboarding';

  /// Check if user has seen onboarding
  bool getHasSeenOnboarding() {
    return _prefs?.getBool(_hasSeenOnboardingKey) ?? false;
  }

  /// Set onboarding as seen
  Future<void> setHasSeenOnboarding(bool hasSeen) async {
    await _prefs?.setBool(_hasSeenOnboardingKey, hasSeen);
  }
}
