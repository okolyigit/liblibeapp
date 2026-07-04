import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';
import '../widgets/app_notification.dart';
import 'libraries.dart';
import 'help_about.dart';
import 'privacy_security.dart';
import 'data_storage_screen.dart';
import 'shopping_list_screen.dart';
import '../widgets/glass_dialog.dart';
import '../widgets/glass_card.dart';
import '../widgets/app_header.dart';

class ProfileScreen extends StatefulWidget {
  final bool showHeader;
  final VoidCallback? onNavigateToEdit;
  final VoidCallback? onNavigateToPassword;
  final VoidCallback? onNavigateToLibraries;
  final VoidCallback? onNavigateToAbout;
  final VoidCallback? onNavigateToHelp;
  final VoidCallback? onNavigateToPrivacy;
  final VoidCallback? onNavigateToNotifications;
  final VoidCallback? onNavigateToShopping;

  const ProfileScreen({
    super.key,
    this.showHeader = true,
    this.onNavigateToEdit,
    this.onNavigateToPassword,
    this.onNavigateToLibraries,
    this.onNavigateToAbout,
    this.onNavigateToHelp,
    this.onNavigateToPrivacy,
    this.onNavigateToNotifications,
    this.onNavigateToShopping,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    const headerHeight = 64.0;

    // Mobile embedded mode (inside home.dart with FloatingNavBar)
    if (widget.showHeader) {
      final statusBarTop = AppHeader.statusBarHeight(context);
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Scrollable content — SafeArea lives inside so the content
            // starts at screen top (beneath the glass header) but still
            // respects bottom insets (nav bar / gesture indicator).
            Positioned.fill(
              child: SafeArea(
                top: false,
                child: _buildContent(
                  context,
                  isDark,
                  isMobile: true,
                  topPadding: headerHeight + statusBarTop,
                ),
              ),
            ),
            // Fixed glass header — paints from y=0 (true screen top),
            // AppHeader adds status bar padding internally.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppHeader(
                  scrollController: _scrollController,
                  title: "Hesabım",
                  actions: [
                    ValueListenableBuilder<int>(
                      valueListenable: NotificationService().unreadCount,
                      builder: (context, count, _) {
                        return GestureDetector(
                          onTap: () {
                            if (widget.onNavigateToNotifications != null) {
                              widget.onNavigateToNotifications!();
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const NotificationsScreen(),
                                ),
                              );
                            }
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: context.subtleTint,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.black12,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  PhosphorIconsRegular.bell,
                                  size: 20,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.6)
                                      : Colors.black54,
                                ),
                                if (count > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF22C55E),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
            ),
          ],
        ),
      );
    }

    // Dashboard mode (with own Scaffold)
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: _buildContent(context, isDark, isMobile: false, topPadding: 0),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    bool isDark, {
    required bool isMobile,
    double topPadding = 0,
  }) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(
        24,
        isMobile ? topPadding + 16 : 24,
        24,
        isMobile ? 120 : 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            children: [
              // Profile Header
              _buildProfileHeader(context, isDark),

              const SizedBox(height: 32),

              // Account Section
              _buildSection(
                context,
                isDark: isDark,
                title: "Hesap",
                items: [
                  _MenuItem(
                    icon: PhosphorIconsRegular.userCircle,
                    label: "Profili Düzenle",
                    onTap: () {
                      if (widget.onNavigateToEdit != null) {
                        widget.onNavigateToEdit!();
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      }
                    },
                  ),
                  _MenuItem(
                    icon: PhosphorIconsRegular.lock,
                    label: "Şifre Değiştir",
                    onTap: () {
                      if (widget.onNavigateToPassword != null) {
                        widget.onNavigateToPassword!();
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChangePasswordScreen(),
                          ),
                        );
                      }
                    },
                  ),
                  // Content/data menus are hidden for the (single) admin
                  // account — admins manage users, not their own library.
                  if (!AuthService().isAdmin)
                    _MenuItem(
                      icon: PhosphorIconsRegular.books,
                      label: "Kütüphanelerim",
                      onTap: () {
                        if (widget.onNavigateToLibraries != null) {
                          widget.onNavigateToLibraries!();
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LibrariesScreen(),
                            ),
                          );
                        }
                      },
                    ),
                  if (!AuthService().isAdmin)
                    _MenuItem(
                      icon: PhosphorIconsRegular.shoppingCart,
                      label: "Alışveriş Listem",
                      onTap: () {
                        if (widget.onNavigateToShopping != null) {
                          widget.onNavigateToShopping!();
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ShoppingListScreen(),
                            ),
                          );
                        }
                      },
                    ),
                  if (!AuthService().isAdmin)
                    _MenuItem(
                      icon: PhosphorIconsRegular.hardDrives,
                      label: "Veri ve Depolama",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DataStorageScreen(),
                          ),
                        );
                      },
                    ),
                ],
              ),

              const SizedBox(height: 24),

              // Preferences Section
              _buildSection(
                context,
                isDark: isDark,
                title: "Tercihler",
                items: [
                  _MenuItem(
                    icon: PhosphorIconsRegular.sun,
                    label: "Tema",
                    trailing: isDark
                        ? (blackThemeNotifier.value ? "Siyah" : "Koyu")
                        : "Açık",
                    onTap: () => _showAppearanceDialog(context, isDark),
                  ),
                  _MenuItem(
                    icon: PhosphorIconsRegular.shieldCheck,
                    label: "Gizlilik ve Güvenlik",
                    onTap: () {
                      if (widget.onNavigateToPrivacy != null) {
                        widget.onNavigateToPrivacy!();
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => _MobilePrivacyScreen(),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Support Section
              _buildSection(
                context,
                isDark: isDark,
                title: "Destek",
                items: [
                  _MenuItem(
                    icon: PhosphorIconsRegular.info,
                    label: "Hakkında",
                    onTap: () {
                      if (widget.onNavigateToAbout != null) {
                        widget.onNavigateToAbout!();
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AboutScreen(
                              onBack: () => Navigator.pop(context),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  _MenuItem(
                    icon: PhosphorIconsRegular.question,
                    label: "Yardım Merkezi",
                    onTap: () {
                      if (widget.onNavigateToHelp != null) {
                        widget.onNavigateToHelp!();
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HelpCenterScreen(
                              onBack: () => Navigator.pop(context),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  _MenuItem(
                    icon: PhosphorIconsRegular.signOut,
                    label: "Çıkış Yap",
                    isDestructive: true,
                    onTap: () => _showSignOutDialog(context, isDark),
                  ),
                  // The single admin account can't delete itself.
                  if (!AuthService().isAdmin)
                    _MenuItem(
                      icon: PhosphorIconsRegular.trash,
                      label: "Hesabımı Sil",
                      isDestructive: true,
                      onTap: () => _showDeleteAccountDialog(context, isDark),
                    ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, bool isDark) {
    final user = AuthService().currentUser;
    final displayName = user?.displayName ?? 'Kullanıcı';
    final email = user?.email ?? '';

    // Get initials from display name
    final initials = displayName.isNotEmpty
        ? displayName
              .split(' ')
              .take(2)
              .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
              .join()
        : 'U';

    return Row(
      children: [
        // Avatar
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.primaryColor,
            boxShadow: [
              BoxShadow(
                color: context.primaryColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _buildUserAvatar(user, initials),
        ),
        const SizedBox(width: 16),
        // Name and Email
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textLightPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : AppColors.textLightSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserAvatar(User? user, String initials) {
    if (user?.photoURL != null) {
      final photoURL = user!.photoURL!;
      if (photoURL.startsWith('asset:')) {
        try {
          final index = int.parse(photoURL.split(':')[1]);
          final icons = [
            PhosphorIconsFill.user,
            PhosphorIconsFill.cat,
            PhosphorIconsFill.dog,
            PhosphorIconsFill.alien,
            PhosphorIconsFill.robot,
          ];
          if (index >= 0 && index < icons.length) {
            return Center(
              child: Icon(icons[index], size: 32, color: Colors.white),
            );
          }
        } catch (_) {
          // Malformed asset index — fall through to default avatar.
        }
      } else {
        return ClipOval(
          child: Image.network(
            photoURL,
            fit: BoxFit.cover,
            width: 64,
            height: 64,
            errorBuilder: (context, error, stackTrace) => Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }
    }

    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required bool isDark,
    required String title,
    required List<_MenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white38 : AppColors.textLightSecondary,
            ),
          ),
        ),
        // Menu Card
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isFirst = index == 0;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  _buildMenuRow(
                    context,
                    item: item,
                    isDark: isDark,
                    isFirst: isFirst,
                    isLast: isLast,
                  ),
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.only(left: 52),
                      child: Divider(
                        height: 1,
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuRow(
    BuildContext context, {
    required _MenuItem item,
    required bool isDark,
    required bool isFirst,
    required bool isLast,
  }) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(16) : Radius.zero,
        bottom: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 22,
              color: item.isDestructive
                  ? Colors.red
                  : (isDark ? Colors.white70 : AppColors.textLightSecondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 15,
                  color: item.isDestructive
                      ? Colors.red
                      : (isDark ? Colors.white : AppColors.textLightPrimary),
                ),
              ),
            ),
            if (item.trailing != null)
              Text(
                item.trailing!,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white38 : AppColors.textLightSecondary,
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              PhosphorIconsRegular.caretRight,
              size: 16,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }

  void _showAppearanceDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Tema",
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textLightPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                PhosphorIconsRegular.sun,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              title: Text(
                "Açık",
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textLightPrimary,
                ),
              ),
              onTap: () async {
                themeNotifier.value = ThemeMode.light;
                final prefs = await PreferencesService.getInstance();
                await prefs.setThemeMode(ThemeMode.light.index);
                await prefs.setBlackTheme(false);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                PhosphorIconsRegular.moon,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              title: Text(
                "Koyu",
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textLightPrimary,
                ),
              ),
              onTap: () async {
                themeNotifier.value = ThemeMode.dark;
                blackThemeNotifier.value = false; // Standard Dark
                final prefs = await PreferencesService.getInstance();
                await prefs.setThemeMode(ThemeMode.dark.index);
                await prefs.setBlackTheme(false);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                PhosphorIconsFill.circle,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              title: Text(
                "Siyah (OLED)",
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textLightPrimary,
                ),
              ),
              onTap: () async {
                themeNotifier.value = ThemeMode.dark;
                blackThemeNotifier.value = true; // Black Mode
                final prefs = await PreferencesService.getInstance();
                await prefs.setThemeMode(ThemeMode.dark.index);
                await prefs.setBlackTheme(true);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                PhosphorIconsRegular.deviceMobile,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              title: Text(
                "Sistem",
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textLightPrimary,
                ),
              ),
              onTap: () async {
                themeNotifier.value = ThemeMode.system;
                blackThemeNotifier.value =
                    false; // Reset to standard for system
                final prefs = await PreferencesService.getInstance();
                await prefs.setThemeMode(ThemeMode.system.index);
                await prefs.setBlackTheme(false);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSignOutDialog(BuildContext context, bool isDark) async {
    final confirmed = await showGlassConfirmDialog(
      context: context,
      title: "Çıkış Yap",
      message: "Hesabınızdan çıkış yapmak istediğinize emin misiniz?",
      icon: PhosphorIconsRegular.signOut,
      confirmText: "Çıkış Yap",
      isDestructive: true,
    );

    if (confirmed == true) {
      await AuthService().signOut();
      if (context.mounted) {
        unawaited(
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteAccountDialog(BuildContext context, bool isDark) async {
    final confirmed = await showGlassConfirmDialog(
      context: context,
      title: "Hesabımı Sil",
      message: "Hesabınızı ve tüm verilerinizi (listeler, kitaplar vb.) silmek istediğinize emin misiniz? Bu işlem geri alınamaz!",
      icon: PhosphorIconsRegular.trash,
      confirmText: "Hesabımı Sil",
      isDestructive: true,
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      
      // Show loading
      unawaited(
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(child: CircularProgressIndicator()),
        ),
      );

      try {
        await AuthService().deleteAccount();
        if (context.mounted) {
          // Navigate to login first
          unawaited(
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            ),
          );
          // Then show success message
          AppNotification.success(
            context,
            "Hesabınız başarıyla silindi",
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Pop loading
          AppNotification.error(context, "Hesap silinemedi: $e");
        }
      }
    }
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;
  final bool isDestructive;

  _MenuItem({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
    this.isDestructive = false,
  });
}

/// A mobile-friendly version of PrivacySecurityScreen with direct navigation
class _MobilePrivacyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            PhosphorIconsRegular.arrowLeft,
            color: isDark ? Colors.white : AppColors.textLightPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Gizlilik ve Güvenlik",
          style: TextStyle(
            fontSize: 20,
            color: isDark ? Colors.white : AppColors.textLightPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildMenuOption(
              context,
              icon: PhosphorIconsRegular.fileText,
              title: "Gizlilik Politikası",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TextContentScreen(
                    title: "Gizlilik Politikası",
                    content: kPrivacyPolicyText,
                    onBack: () => Navigator.pop(context),
                  ),
                ),
              ),
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildMenuOption(
              context,
              icon: PhosphorIconsRegular.scroll,
              title: "Kullanım Koşulları",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TextContentScreen(
                    title: "Kullanım Koşulları",
                    content: kTermsOfUseText,
                    onBack: () => Navigator.pop(context),
                  ),
                ),
              ),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: context.primaryColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textLightPrimary,
                ),
              ),
            ),
            Icon(
              PhosphorIconsRegular.caretRight,
              color: isDark ? Colors.white54 : Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
