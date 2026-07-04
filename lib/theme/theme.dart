import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand
  static const lime = Color(0xFF84CC16); // --color-secondary (Web)
  static const limeDark = Color(0xFF65A30D); // Darker lime for light mode
  static const emerald = Color(0xFF10B981); // --color-primary (Web)
  static const emeraldDark = Color(0xFF059669); // Darker emerald
  static const evergreen = Color(0xFF0A0A0A); // Web Koyu Arka Plan

  // Light
  static const bgLightPrimary = Color(0xFFFFFFFF); // Cards / Sidebar
  static const bgLightSurface = Color(0xFFFFFFFF); // Background (White)
  static const textLightPrimary = Color(0xFF0A0A0A);
  static const textLightSecondary = Color(0xFF71717A); // Muted gray

  // Dark (Koyu Tema - Yeşile dönük web uyumu)
  static const bgDarkPrimary = Color(0xFF0B1412); // --color-bg-dark
  static const bgDarkSurface = Color(0xFF0B1412); // --color-bg-panel
  static const textDarkPrimary = Color(0xFFFFFFFF); // --color-text-main
  static const textDarkSecondary = Color(0xFFA1A1AA); // --color-text-muted

  // Pure Black for OLED
  static const bgBlackPrimary = Color(0xFF000000);
  static const bgBlackSurface = Color(0xFF0A0A0A);

  // Glassmorphism (Web)
  static const glassBgLight = Colors.white; // Pure white for light mode
  static const glassBorderLight = Color(0x14000000); // 8% black for light border
  static const glassBgDark = Color(0x08FFFFFF); // 3% white
  static const glassBorderDark = Color(0x14FFFFFF); // 8% white

  // Aliases for compatibility with Dashboard logic
  static const accentGreen = emerald;
  static const accentOrange = Color(0xFFFF9800);
  static const accentBlue = Color(0xFF2196F3);
  static const purple = Color(0xFF9C27B0);
}

class AppTheme {
  static TextTheme _buildTextTheme(
    TextTheme base,
    Color mainColor,
    Color subColor,
  ) {
    return GoogleFonts.workSansTextTheme(base).copyWith(
      displayLarge: GoogleFonts.outfit(
        color: mainColor,
        fontWeight: FontWeight.bold,
        height: 1.1,
      ),
      displayMedium: GoogleFonts.outfit(
        color: mainColor,
        fontWeight: FontWeight.bold,
        height: 1.1,
      ),
      displaySmall: GoogleFonts.outfit(
        color: mainColor,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: GoogleFonts.outfit(
        color: mainColor,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: GoogleFonts.outfit(
        color: mainColor,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: GoogleFonts.outfit(
        color: mainColor,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.workSans(color: mainColor),
      bodyMedium: GoogleFonts.workSans(color: subColor),
    );
  }

  /// Centralized Theme Builder
  static ThemeData buildTheme({
    required Brightness brightness,
    required Color primary,
    required Color secondary,
    required Color background,
    required Color surface,
    required Color onSurface,
    required Color textPrimary,
    required Color textSecondary,
    required Color surfaceTint,
    required Color glassBg,
    required Color glassBorder,
  }) {
    final base = brightness == Brightness.dark ? ThemeData.dark() : ThemeData.light();
    final isDark = brightness == Brightness.dark;

    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: secondary,
        surface: surface,
        onSurface: onSurface,
        surfaceTint: surfaceTint,
        brightness: brightness,
      ),
      textTheme: _buildTextTheme(base.textTheme, textPrimary, textSecondary),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: glassBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: glassBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: glassBorder, width: 1),
        ),
        titleTextStyle: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: GoogleFonts.workSans(
          color: textSecondary,
          fontSize: 14,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent, // Default to transparent for glass effect
        modalBackgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Dropdown Menu Theme
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(surface),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: glassBorder),
            ),
          ),
          elevation: const WidgetStatePropertyAll(4),
        ),
      ),

      // Popup Menu Theme
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: glassBorder),
        ),
        elevation: 4,
        textStyle: GoogleFonts.workSans(
          color: textPrimary,
          fontSize: 14,
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: isDark ? const Color(0xFF1D3D47) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: glassBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      iconTheme: IconThemeData(
        color: textPrimary,
        size: 24,
      ),
    );
  }

  static ThemeData get lightTheme {
    return buildTheme(
      brightness: Brightness.light,
      primary: AppColors.emerald,
      secondary: AppColors.limeDark,
      background: AppColors.bgLightSurface,
      surface: Colors.white,
      onSurface: AppColors.textLightPrimary,
      textPrimary: AppColors.textLightPrimary,
      textSecondary: AppColors.textLightSecondary,
      surfaceTint: AppColors.emerald,
      glassBg: AppColors.glassBgLight,
      glassBorder: AppColors.glassBorderLight,
    );
  }

  static ThemeData get darkTheme {
    return buildTheme(
      brightness: Brightness.dark,
      primary: AppColors.emerald,
      secondary: AppColors.lime,
      background: AppColors.bgDarkPrimary,
      surface: AppColors.bgDarkSurface,
      onSurface: AppColors.textDarkPrimary,
      textPrimary: AppColors.textDarkPrimary,
      textSecondary: AppColors.textDarkSecondary,
      surfaceTint: AppColors.evergreen,
      glassBg: AppColors.glassBgDark,
      glassBorder: AppColors.glassBorderDark,
    );
  }

  static ThemeData get blackTheme {
    return buildTheme(
      brightness: Brightness.dark,
      primary: AppColors.emerald,
      secondary: AppColors.lime,
      background: AppColors.bgBlackPrimary,
      surface: AppColors.bgBlackSurface,
      onSurface: AppColors.textDarkPrimary,
      textPrimary: AppColors.textDarkPrimary,
      textSecondary: AppColors.textDarkSecondary,
      surfaceTint: const Color(0xFF1A1A1A),
      glassBg: AppColors.glassBgDark,
      glassBorder: AppColors.glassBorderDark,
    );
  }
}

// Global Theme Notifier
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
// Preference for Black Mode (True: Black, False: Standard Dark)
final ValueNotifier<bool> blackThemeNotifier = ValueNotifier(false);
// Active app locale. Defaults to Turkish (the app's primary language); the
// rest of the UI is being migrated to AppLocalizations incrementally.
final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('tr'));

// Theme Helper Extension
extension ThemeHelper on BuildContext {
  /// Check if current theme is Black mode
  bool get isBlackTheme =>
      blackThemeNotifier.value && Theme.of(this).brightness == Brightness.dark;

  /// Returns the scaffold background color of the current theme
  /// This is the "main" background color that changes per theme
  Color get themeBackground {
    if (isBlackTheme) return AppColors.bgBlackPrimary;
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? AppColors.bgDarkPrimary : AppColors.bgLightSurface;
  }

  /// Returns a subtle tint background color based on theme
  /// Light: light grey, Dark: lighter evergreen, Black: dark grey
  Color get subtleTint {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    final tint = Theme.of(this).colorScheme.surfaceTint;
    return tint.withValues(alpha: isDark ? 0.15 : 0.12);
  }

  /// Returns a slightly stronger tint background color
  Color get mediumTint {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    final tint = Theme.of(this).colorScheme.surfaceTint;
    return tint.withValues(alpha: isDark ? 0.25 : 0.2);
  }

  /// Whether the current theme is dark (or black). Shorthand for the
  /// repeated `context.isDark` pattern.
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Returns the card/surface background color for the current theme
  /// Use this for container backgrounds instead of hardcoded colors
  Color get surfaceColor => Theme.of(this).colorScheme.surface;

  // === Accent Color Properties ===

  /// Primary accent color (emerald by default, customizable per theme)
  Color get primaryColor => Theme.of(this).colorScheme.primary;

  /// Secondary accent color (lime by default, customizable per theme)
  Color get secondaryColor => Theme.of(this).colorScheme.secondary;

  /// Primary color with alpha for borders (increased for visibility)
  Color get primaryBorder => primaryColor.withValues(alpha: 0.45);

  /// Primary color with lower alpha for subtle highlights (15% opacity)
  Color get primaryTint => primaryColor.withValues(alpha: 0.15);

  /// Primary color with medium alpha (50% opacity)
  Color get primaryMedium => primaryColor.withValues(alpha: 0.5);
}
