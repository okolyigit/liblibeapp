/// Environment configuration loaded from --dart-define at build time
///
/// Usage in build:
/// flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=your-client-id
/// flutter build apk --dart-define=GOOGLE_WEB_CLIENT_ID=your-client-id
///
/// For development, you can create a .env file and use a script to load them,
/// or just pass them directly in the run command.
class EnvConfig {
  // Google OAuth Web Client ID (for web platform)
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '676632601870-sjomhag968529tubjtgdc3i3oulcflti.apps.googleusercontent.com',
  );

  // ReCAPTCHA v3 Site Key (for App Check on Web)
  // Get this from: https://www.google.com/recaptcha/admin
  static const String recaptchaSiteKey = String.fromEnvironment(
    'RECAPTCHA_SITE_KEY',
    defaultValue: 'your-recaptcha-site-key',
  );

  // Add other environment-specific configs here
  // static const String apiBaseUrl = String.fromEnvironment(
  //   'API_BASE_URL',
  //   defaultValue: 'https://api.example.com',
  // );

  // Check if running in production mode
  static const bool isProduction =
      String.fromEnvironment('ENVIRONMENT', defaultValue: 'development') ==
      'production';
}
