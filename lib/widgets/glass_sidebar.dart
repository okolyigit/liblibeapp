import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/theme.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

class GlassSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onProfileTap;
  final VoidCallback onCtaTap;
  final bool isAdmin;

  const GlassSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onProfileTap,
    required this.onCtaTap,
    this.isAdmin = false,
  });

  @override
  State<GlassSidebar> createState() => _GlassSidebarState();
}

class _GlassSidebarState extends State<GlassSidebar> {
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final width = widget.isExpanded ? 280.0 : 80.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      width: width,
      height: double.infinity,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.glassBgDark : AppColors.glassBgLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? AppColors.glassBorderDark
              : AppColors.glassBorderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return isDark
                ? BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: _buildSidebarContent(isDark, constraints.maxHeight),
                  )
                : _buildSidebarContent(isDark, constraints.maxHeight);
          },
        ),
      ),
    );
  }

  Widget _buildSidebarContent(bool isDark, double maxHeight) {
    return OverflowBox(
      minWidth: 280,
      maxWidth: 280,
      minHeight: maxHeight,
      maxHeight: maxHeight,
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top spacing & Logo Section
          const SizedBox(height: 16),
          _SidebarLogo(isExpanded: widget.isExpanded),
          const SizedBox(height: 16),

          // Navigation Items
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: widget.isAdmin
                    ? [
                        _SidebarItem(
                          icon: PhosphorIconsRegular.house,
                          label: "Ana Sayfa",
                          isSelected: widget.selectedIndex == 0,
                          isExpanded: widget.isExpanded,
                          isDark: isDark,
                          onTap: () => widget.onItemSelected(0),
                        ),
                        _SidebarItem(
                          icon: PhosphorIconsRegular.chartBar,
                          label: "İstatistikler",
                          isSelected: widget.selectedIndex == 1,
                          isExpanded: widget.isExpanded,
                          isDark: isDark,
                          onTap: () => widget.onItemSelected(1),
                        ),
                        _SidebarItem(
                          icon: PhosphorIconsRegular.users,
                          label: "Kullanıcılar",
                          isSelected: widget.selectedIndex == 2,
                          isExpanded: widget.isExpanded,
                          isDark: isDark,
                          onTap: () => widget.onItemSelected(2),
                        ),
                      ]
                    : [
                        _SidebarItem(
                          icon: PhosphorIconsRegular.house,
                          label: "Ana Sayfa",
                          isSelected: widget.selectedIndex == 0,
                          isExpanded: widget.isExpanded,
                          isDark: isDark,
                          onTap: () => widget.onItemSelected(0),
                        ),
                        _SidebarItem(
                          icon: PhosphorIconsRegular.bookOpen,
                          label: "Kitaplar",
                          isSelected: widget.selectedIndex == 1,
                          isExpanded: widget.isExpanded,
                          isDark: isDark,
                          onTap: () => widget.onItemSelected(1),
                        ),
                        _SidebarItem(
                          icon: PhosphorIconsRegular.listBullets,
                          label: "Listeler",
                          isSelected: widget.selectedIndex == 2,
                          isExpanded: widget.isExpanded,
                          isDark: isDark,
                          onTap: () => widget.onItemSelected(2),
                        ),
                        _SidebarItem(
                          icon: PhosphorIconsRegular.books,
                          label: "Kütüphanelerim",
                          isSelected: widget.selectedIndex == 9,
                          isExpanded: widget.isExpanded,
                          isDark: isDark,
                          onTap: () => widget.onItemSelected(9),
                        ),
                        _SidebarItem(
                          icon: PhosphorIconsRegular.shoppingCart,
                          label: "Alışveriş Listem",
                          isSelected:
                              widget.selectedIndex == 17 ||
                              widget.selectedIndex == 18 ||
                              widget.selectedIndex == 19,
                          isExpanded: widget.isExpanded,
                          isDark: isDark,
                          onTap: () => widget.onItemSelected(17),
                        ),
                      ],
              ),
            ),
          ),

          // Profile Section (above CTA)
          _SidebarProfile(
            isExpanded: widget.isExpanded,
            isDark: isDark,
            isSelected: widget.selectedIndex == 3 || widget.selectedIndex == 4,
            onTap: widget.onProfileTap,
          ),

          // Footer CTA
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.isExpanded ? 16 : 12,
              vertical: 16,
            ),
            child: _SidebarCTA(
              isExpanded: widget.isExpanded,
              isDark: isDark,
              onTap: widget.onCtaTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarProfile extends StatefulWidget {
  final bool isExpanded;
  final bool isDark;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarProfile({
    required this.isExpanded,
    required this.isDark,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarProfile> createState() => _SidebarProfileState();
}

class _SidebarProfileState extends State<_SidebarProfile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final displayName = user?.displayName ?? 'Kullanıcı';

    // Get initials from display name
    final initials = displayName.isNotEmpty
        ? displayName
              .split(' ')
              .take(2)
              .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
              .join()
        : 'U';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(vertical: 8),
            width: widget.isExpanded ? 248 : 48,
            height: 48,
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? context.primaryColor.withValues(
                      alpha: widget.isDark ? 0.2 : 0.15,
                    )
                  : (_isHovered
                        ? (widget.isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05))
                        : Colors.transparent),
              borderRadius: BorderRadius.circular(widget.isExpanded ? 16 : 24),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: context.primaryColor.withValues(alpha: 0.15),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: OverflowBox(
              minWidth: 48,
              maxWidth: 248,
              minHeight: 32,
              maxHeight: 32,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 48,
                    child: Center(
                      child: ValueListenableBuilder<int>(
                        valueListenable: NotificationService().unreadCount,
                        builder: (context, count, child) {
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: context.primaryColor,
                                ),
                                child: _buildUserAvatar(user, initials),
                              ),
                              if (count > 0)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF22C55E),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: widget.isDark
                                            ? const Color(0xFF1E1E1E)
                                            : Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: widget.isExpanded ? 1.0 : 0.0,
                      child: Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: widget.isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: widget.isSelected
                              ? (widget.isDark
                                    ? Colors.white
                                    : AppColors.textLightPrimary)
                              : (widget.isDark
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : AppColors.textLightPrimary),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
              child: Icon(icons[index], size: 16, color: Colors.white),
            );
          }
        } catch (_) {
          // Malformed asset index — fall through to default avatar.
        }
      } else {
        return ClipOval(
          child: CachedNetworkImage(
            imageUrl: photoURL,
            fit: BoxFit.cover,
            width: 30,
            height: 30,
            placeholder: (context, url) => Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
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
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isExpanded;
  final bool isDark;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isExpanded,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(vertical: 12),
            width: widget.isExpanded ? 248 : 48,
            height: 48,
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? context.primaryColor.withValues(
                      alpha: widget.isDark ? 0.2 : 0.15,
                    )
                  : (_isHovering
                        ? (widget.isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05))
                        : Colors.transparent),
              borderRadius: BorderRadius.circular(widget.isExpanded ? 16 : 24),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: context.primaryColor.withValues(alpha: 0.15),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: OverflowBox(
              minWidth: 48,
              maxWidth: 248,
              minHeight: 24,
              maxHeight: 24,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 48,
                    child: Center(
                      child: Icon(
                        widget.icon,
                        size: 22,
                        color: widget.isSelected
                            ? (widget.isDark
                                  ? Colors.white
                                  : AppColors.textLightPrimary)
                            : (widget.isDark
                                  ? Colors.white.withValues(alpha: 0.5)
                                  : AppColors.textLightSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: widget.isExpanded ? 1.0 : 0.0,
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: widget.isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: widget.isSelected
                              ? (widget.isDark
                                    ? Colors.white
                                    : AppColors.textLightPrimary)
                              : (widget.isDark
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : AppColors.textLightPrimary),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarCTA extends StatelessWidget {
  final bool isExpanded;
  final bool isDark;
  final VoidCallback onTap;

  const _SidebarCTA({
    required this.isExpanded,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      height: 56,
      width: isExpanded ? 248 : 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.emerald, AppColors.lime],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (isDark)
            BoxShadow(
              color: AppColors.emerald.withValues(alpha: 0.4),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: OverflowBox(
              minWidth: 248,
              maxWidth: 248,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(width: 16),
                  const Icon(PhosphorIconsBold.plus, color: Color(0xFF1D3D47)),
                  const SizedBox(width: 16),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: isExpanded ? 1.0 : 0.0,
                    child: const Text(
                      "Ekle",
                      style: TextStyle(
                        color: Color(0xFF1D3D47),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarLogo extends StatelessWidget {
  final bool isExpanded;

  const _SidebarLogo({required this.isExpanded});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final textColor = isDark ? Colors.white : context.primaryColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 48,
      child: OverflowBox(
        minWidth: 48,
        maxWidth: 248,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              width: 48,
              child: Center(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      isDark
                          ? 'assets/icon/lighticon.png'
                          : 'assets/icon/darkicon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isExpanded ? 1.0 : 0.0,
                child: Text(
                  "Liblibe",
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
