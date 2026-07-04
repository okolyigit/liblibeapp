import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/web_auth_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/preferences_service.dart';
import 'providers/app_data_provider.dart';
import 'theme/theme.dart';
import 'l10n/app_localizations.dart';
import 'config/env_config.dart';
import 'package:provider/provider.dart';
import 'widgets/background_blobs.dart';
import 'widgets/offline_banner.dart';
// Conditional import for web logic
import 'utils/web_helpers.dart'
    if (dart.library.io) 'utils/mobile_helpers.dart';

void main() async {
  // Catch errors thrown during sync initialization (zone-level) so they reach Crashlytics.
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Draw behind the system status/navigation bars and make them transparent
      // so the glass header can extend all the way up to the device top.
      // Icon brightness is set for the dark theme default; per-screen overrides
      // can be added later with AnnotatedRegion<SystemUiOverlayStyle>.
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
      );

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Route Flutter framework errors to Crashlytics (non-web).
      // Skip collection in debug mode to avoid noise during development.
      if (!kIsWeb) {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
          !kDebugMode,
        );
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }

      // Initialize Firebase App Check for enhanced security.
      // Uses Play Integrity on Android, DeviceCheck on iOS, reCAPTCHA on Web.
      // Wrapped in try/catch so a failed attestation doesn't block app start —
      // Firestore requests will still fail (by design) but the app can render.
      try {
        await FirebaseAppCheck.instance.activate(
          androidProvider: kDebugMode
              ? AndroidProvider.debug
              : AndroidProvider.playIntegrity,
          appleProvider: kDebugMode
              ? AppleProvider.debug
              : AppleProvider.deviceCheck,
          webProvider: ReCaptchaV3Provider(EnvConfig.recaptchaSiteKey),
        );
      } catch (e, stack) {
        debugPrint('[AppCheck] activation failed: $e');
        if (!kIsWeb && !kDebugMode) {
          unawaited(
            FirebaseCrashlytics.instance.recordError(e, stack, fatal: false),
          );
        }
      }

      // Firestore persistence caches *documents* (book fields, queries), not HTTP image bytes.
      // Cover images use disk cache via CachedNetworkImage in [AppImage] / other widgets.
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        // Generous cap for metadata + queries; avoids unbounded on-device growth.
        cacheSizeBytes: 100 * 1024 * 1024,
      );

      // Load saved preferences
      final prefs = await PreferencesService.getInstance();
      final savedThemeMode = prefs.getThemeMode();
      themeNotifier.value = ThemeMode.values[savedThemeMode];
      blackThemeNotifier.value = prefs.getBlackTheme();
      localeNotifier.value = Locale(prefs.getLanguageCode());

      // Initialize Notification Service before runApp so FCM token + permission
      // state are ready when the first screen mounts.
      await NotificationService().init();

      // Initialize AuthService to set up auth state listener for automatic library/favorites creation
      unawaited(AuthService().init());

      runApp(const LiblibeApp());

      if (kIsWeb) {
        // Hide the loading screen after the app is initialized
        WidgetsBinding.instance.addPostFrameCallback((_) {
          hideWebLoadingScreen();
        });
      }
    },
    (error, stack) {
      debugPrint('[Zone] uncaught async error: $error');
      if (!kIsWeb && !kDebugMode) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
    },
  );
}

class LiblibeApp extends StatelessWidget {
  const LiblibeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppDataProvider(),
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, mode, child) {
          return ValueListenableBuilder<bool>(
            valueListenable: blackThemeNotifier,
            builder: (context, isBlack, child) {
              return ValueListenableBuilder<Locale>(
                valueListenable: localeNotifier,
                builder: (context, locale, child) {
                  return MaterialApp(
                    title: 'Liblibe',
                    debugShowCheckedModeBanner: false,
                    locale: locale,
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    supportedLocales: AppLocalizations.supportedLocales,
                    theme: AppTheme.lightTheme,
                    darkTheme: isBlack
                        ? AppTheme.blackTheme
                        : AppTheme.darkTheme,
                    themeMode: mode,
                    builder: (context, child) => Scaffold(
                      backgroundColor: context.themeBackground,
                      body: Stack(
                        children: [
                          const BackgroundBlobs(),
                          if (child != null)
                            OfflineBanner(
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  scaffoldBackgroundColor: Colors.transparent,
                                ),
                                child: child,
                              ),
                            ),
                        ],
                      ),
                    ),
                    home: _buildHomeScreen(),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Determines the home screen based on platform and auth state
  Widget _buildHomeScreen() {
    // Web platform: Use WebAuthScreen
    if (kIsWeb) {
      return ValueListenableBuilder<bool>(
        valueListenable: AuthService().isInitializing,
        builder: (context, isInitializing, _) {
          if (isInitializing) {
            return const _SplashScreen();
          }
          return StreamBuilder<User?>(
            stream: AuthService().authStateChanges,
            initialData: AuthService().currentUser,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                // Wait until the role claim is resolved so admins never flash
              // the normal user dashboard. DashboardScreen itself is role-aware.
              return ValueListenableBuilder<bool>(
                valueListenable: AuthService().roleLoaded,
                builder: (context, loaded, _) =>
                    loaded ? const DashboardScreen() : const _SplashScreen(),
              );
              }
              return const WebAuthScreen();
            },
          );
        },
      );
    }

    // Mobile platform: Direkt login/dashboard akışı
    return ValueListenableBuilder<bool>(
      valueListenable: AuthService().isInitializing,
      builder: (context, isInitializing, _) {
        if (isInitializing) {
          return const _SplashScreen();
        }
        return StreamBuilder<User?>(
          stream: AuthService().authStateChanges,
          initialData: AuthService().currentUser,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              // Wait until the role claim is resolved so admins never flash
              // the normal user dashboard. DashboardScreen itself is role-aware.
              return ValueListenableBuilder<bool>(
                valueListenable: AuthService().roleLoaded,
                builder: (context, loaded, _) =>
                    loaded ? const DashboardScreen() : const _SplashScreen(),
              );
            }
            return const LoginScreen();
          },
        );
      },
    );
  }
}

/// Simple splash screen shown during auth initialization
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Image.asset('assets/icon/icon.png', width: 120, height: 120),
      ),
    );
  }
}
