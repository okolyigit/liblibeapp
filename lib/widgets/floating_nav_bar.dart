import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/theme.dart';
import 'create_list_bottom_sheet.dart';
import '../screens/add_book_screen.dart';
import '../screens/admin/admin_add_user_screen.dart';
import '../screens/add_shopping_item_screen.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FloatingNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final ValueChanged<bool>? onMenuStateChanged;
  final bool isAdmin;

  const FloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.onMenuStateChanged,
    this.isAdmin = false,
  });

  @override
  State<FloatingNavBar> createState() => FloatingNavBarState();
}

class FloatingNavBarState extends State<FloatingNavBar>
    with SingleTickerProviderStateMixin {
  bool _isMenuOpen = false;
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _menuAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: -math.pi / 4, // Exactly 45 degrees counter-clockwise
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _menuAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get isMenuOpen => _isMenuOpen;

  void closeMenu() {
    if (_isMenuOpen) {
      _toggleMenu();
    }
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
    widget.onMenuStateChanged?.call(_isMenuOpen);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final keyboardIsOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    // Hide the navbar when keyboard is open
    if (keyboardIsOpen) {
      return const SizedBox.shrink();
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Dismiss barrier when menu is open - covers area above the navbar
        if (_isMenuOpen)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: -1000, // Extend far above to cover the screen
            child: GestureDetector(
              onTap: _toggleMenu,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),

        // Main content
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick Actions Menu (above navbar)
            if (_isMenuOpen)
              Padding(
                padding: const EdgeInsets.only(right: 24, bottom: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ScaleTransition(
                    scale: _menuAnimation,
                    alignment: Alignment.bottomRight,
                    child: FadeTransition(
                      opacity: _menuAnimation,
                      child: _buildQuickActionsMenu(isDark),
                    ),
                  ),
                ),
              ),

            // Nav Bar and FAB Row
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: [
                  // Glass container for nav items
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: isDark
                                  ? [
                                      context.themeBackground.withValues(
                                        alpha: 0.85,
                                      ),
                                      context.themeBackground.withValues(
                                        alpha: 0.75,
                                      ),
                                    ]
                                  : [
                                      Colors.white.withValues(alpha: 0.9),
                                      Colors.white.withValues(alpha: 0.75),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : Colors.grey.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.3 : 0.12,
                                ),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: _buildNavItem(
                                      context,
                                      0,
                                      PhosphorIconsRegular.house,
                                      "Ana Sayfa",
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildNavItem(
                                      context,
                                      1,
                                      widget.isAdmin
                                          ? PhosphorIconsRegular.chartBar
                                          : PhosphorIconsRegular.bookOpen,
                                      widget.isAdmin
                                          ? "İstatistikler"
                                          : "Kitaplar",
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildNavItem(
                                      context,
                                      2,
                                      widget.isAdmin
                                          ? PhosphorIconsRegular.users
                                          : PhosphorIconsRegular.listBullets,
                                      widget.isAdmin
                                          ? "Kullanıcılar"
                                          : "Listeler",
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildProfileNavItem(context),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Animated FAB
                  GestureDetector(
                    onTap: _toggleMenu,
                    child: Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.emerald, AppColors.lime],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emerald.withValues(
                              alpha: isDark ? 0.5 : 0.35,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: AnimatedBuilder(
                        animation: _rotationAnimation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotationAnimation.value,
                            child: Icon(
                              PhosphorIconsBold.plus,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1D3D47),
                              size: 24,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionsMenu(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(8),
          width: 260,
          decoration: BoxDecoration(
            color: isDark
                ? context.surfaceColor.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.95), // Near opaque
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.primaryColor.withValues(
                alpha: 0.4,
              ), // Stronger border
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.isAdmin
                ? [
                    _buildMenuOption(
                      icon: PhosphorIconsFill.userPlus,
                      label: "Kullanıcı Ekle",
                      onTap: () {
                        _toggleMenu();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminAddUserScreen(),
                          ),
                        );
                      },
                      isDark: isDark,
                    ),
                  ]
                : [
                    _buildMenuOption(
                      icon: PhosphorIconsFill.bookOpen,
                      label: "Kitap Ekle",
                      onTap: () {
                        _toggleMenu();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddBookScreen(),
                          ),
                        );
                      },
                      isDark: isDark,
                    ),
                    const Divider(height: 1, color: Colors.white12),
                    _buildMenuOption(
                      icon: PhosphorIconsRegular.listPlus,
                      label: "Liste Ekle",
                      onTap: () {
                        _toggleMenu();
                        showCreateListBottomSheet(context: context);
                      },
                      isDark: isDark,
                    ),
                    const Divider(height: 1, color: Colors.white12),
                    _buildMenuOption(
                      icon: PhosphorIconsRegular.shoppingCart,
                      label: "Alışveriş Listesine Ekle",
                      onTap: () {
                        _toggleMenu();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddShoppingItemScreen(),
                          ),
                        );
                      },
                      isDark: isDark,
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: context.primaryColor, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white : AppColors.textLightPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final isSelected = widget.selectedIndex == index;
    final isDark = context.isDark;

    // Light mode: Text always black/dark, Icon black unless selected (then white)
    // Dark mode: Text white if selected else grey, Icon white if selected else grey
    final textColor = isDark
        ? (isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6))
        : (isSelected
              ? AppColors.textLightPrimary
              : AppColors.textLightSecondary);

    // Icon stays dark in light mode, white in dark mode
    final iconColor = isDark
        ? (isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6))
        : (isSelected
              ? AppColors.textLightPrimary
              : AppColors.textLightSecondary);

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: GestureDetector(
        onTap: () {
          if (_isMenuOpen) closeMenu();
          widget.onItemSelected(index);
        },
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: isSelected
                      ? BoxDecoration(
                          color: context.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: context.primaryColor.withValues(
                                alpha: 0.15,
                              ),
                              blurRadius: 10,
                            ),
                          ],
                        )
                      : null,
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileNavItem(BuildContext context) {
    final isSelected = widget.selectedIndex == 3;
    final isDark = context.isDark;

    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final isLoggedIn = user != null;

        // Light mode: Text always black/dark
        // Dark mode: Text white if selected else grey
        final textColor = isDark
            ? (isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6))
            : (isSelected
                  ? AppColors.textLightPrimary
                  : AppColors.textLightSecondary);

        return GestureDetector(
          onTap: () {
            if (_isMenuOpen) closeMenu();
            if (!isLoggedIn) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            } else {
              widget.onItemSelected(3);
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(
                      2,
                    ), // Smaller padding for avatar
                    decoration: isSelected
                        ? BoxDecoration(
                            color: context.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: context.primaryColor.withValues(
                                  alpha: 0.15,
                                ),
                                blurRadius: 10,
                              ),
                            ],
                          )
                        : null,
                    child: Container(
                      width: 30, // Fixed size for consistency
                      height: 30,
                      alignment: Alignment.center,
                      child: isLoggedIn
                          ? _buildUserAvatar(user, isDark)
                          : Icon(
                              PhosphorIconsRegular.user,
                              size: 24,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textLightPrimary,
                            ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isLoggedIn ? "Profil" : "Giriş",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserAvatar(User user, bool isDark) {
    final photoURL = user.photoURL;

    if (photoURL != null) {
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
            return Icon(
              icons[index],
              size: 24,
              color: isDark ? Colors.white : AppColors.textLightPrimary,
            );
          }
        } catch (_) {
          // Malformed asset index — fall through to default avatar.
        }
      } else {
        return ClipOval(
          child: CachedNetworkImage(
            imageUrl: photoURL,
            width: 24,
            height: 24,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => Icon(
              PhosphorIconsFill.userCircle,
              size: 24,
              color: isDark ? Colors.white : AppColors.textLightPrimary,
            ),
          ),
        );
      }
    }

    return Icon(
      PhosphorIconsFill.userCircle,
      size: 24,
      color: isDark ? Colors.white : AppColors.textLightPrimary,
    );
  }
}
