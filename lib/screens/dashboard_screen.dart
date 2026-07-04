import 'dart:ui';

import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/theme.dart';
import 'home.dart';
import 'books.dart';
import '../models/book.dart';
import 'lists.dart';
import 'add_book_screen.dart';
import '../widgets/universal_search_field.dart';
import '../widgets/create_list_bottom_sheet.dart';
import '../widgets/glass_sidebar.dart';
import 'profile_screen.dart';
import 'edit_profile_screen.dart';
import '../services/auth_service.dart';
import 'admin/admin_add_user_screen.dart';
import 'admin/admin_user_detail_screen.dart';
import 'admin/tabs/admin_home_tab.dart';
import 'admin/tabs/admin_stats_tab.dart';
import 'admin/tabs/admin_users_tab.dart';
import 'book_detail.dart';
import 'privacy_security.dart';
import 'help_about.dart';
import 'list_detail.dart';
import 'libraries.dart';
import 'library_detail.dart';
import 'notifications_screen.dart';
import '../models/reading_list.dart';
import '../models/library.dart';
import 'change_password_screen.dart';
import 'add_shopping_item_screen.dart';
import 'shopping_list_screen.dart';
import 'shopping_item_detail.dart';
import '../models/shopping_item.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Wait until the role is resolved, then build reactively. This is robust to
    // EVERY entry path — including login/register screens that pushReplacement
    // straight to DashboardScreen — so admins never briefly see the user UI and
    // it self-corrects without a manual refresh.
    return ValueListenableBuilder<bool>(
      valueListenable: AuthService().roleLoaded,
      builder: (context, loaded, _) {
        if (!loaded) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return ValueListenableBuilder<String>(
          valueListenable: AuthService().roleNotifier,
          builder: (context, role, _) {
            final isAdmin = role == 'admin';
            return LayoutBuilder(
              builder: (context, constraints) {
                return Scaffold(
                  backgroundColor: Colors.transparent,
                  resizeToAvoidBottomInset: true,
                  body: constraints.maxWidth > 670
                      ? _WebDashboard(
                          width: constraints.maxWidth,
                          selectedIndex: _selectedIndex,
                          onItemSelected: (i) =>
                              setState(() => _selectedIndex = i),
                          isAdmin: isAdmin,
                        )
                      : HomeScreen(
                          selectedIndex: _selectedIndex,
                          onItemSelected: (i) =>
                              setState(() => _selectedIndex = i),
                          isAdmin: isAdmin,
                        ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _WebDashboard extends StatefulWidget {
  final double width;
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isAdmin;

  const _WebDashboard({
    required this.width,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isAdmin = false,
  });

  @override
  State<_WebDashboard> createState() => _WebDashboardState();
}

class _WebDashboardState extends State<_WebDashboard>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  bool _isMenuOpen = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Selected items for detail pages
  Book? _selectedBook;
  ReadingList? _selectedList;
  Library? _selectedLibrary;
  bool _isEditingBook = false;
  ShoppingItem? _selectedShoppingItem;

  // Admin: selected user for the in-content detail page, and a counter that
  // forces the users list to reload after a change (it's kept alive in the
  // IndexedStack, so a changing key rebuilds it fresh).
  String? _selectedUserUid;
  int _adminUsersReloadKey = 0;

  @override
  void initState() {
    super.initState();
    // Initialize expanded state based on width
    _isExpanded = widget.width > 865;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
  }

  @override
  void didUpdateWidget(_WebDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-collapse if crossing the threshold downwards
    if (oldWidget.width >= 865 && widget.width < 865) {
      if (_isExpanded) {
        setState(() => _isExpanded = false);
      }
    }
    // Auto-expand if crossing the threshold upwards
    if (oldWidget.width < 865 && widget.width >= 865) {
      if (!_isExpanded) {
        setState(() => _isExpanded = true);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            // Close menus when tapping outside
            if (_isMenuOpen) {
              _animationController.reverse();
              setState(() {
                _isMenuOpen = false;
              });
            }
          },
          child: Container(
            color: Colors.transparent,
            child: Row(
              children: [
                // Sidebar (animate edilmiş genişlik)
                // Glass Sidebar
                GlassSidebar(
                  selectedIndex: widget.selectedIndex,
                  onItemSelected: widget.onItemSelected,
                  isExpanded: _isExpanded,
                  onToggleExpand: () =>
                      setState(() => _isExpanded = !_isExpanded),
                  onProfileTap: () => widget.onItemSelected(3),
                  onCtaTap: _toggleMenu,
                  isAdmin: widget.isAdmin,
                ),
                // Main Content Area
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color:
                            Theme.of(context).cardTheme.shape
                                is RoundedRectangleBorder
                            ? (Theme.of(context).cardTheme.shape
                                      as RoundedRectangleBorder)
                                  .side
                                  .color
                            : context.primaryBorder.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.08),
                          blurRadius: 32,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: _buildWebContent(context, isDark),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Quick Actions Menu with tap-outside-to-close barrier
        if (_isMenuOpen) ...[
          // Full screen tap barrier
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _animationController.reverse();
                setState(() => _isMenuOpen = false);
              },
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          // The actual menu
          Positioned(
            left: _isExpanded ? 240 : 80, // Align with sidebar
            bottom: 80, // Above the CTA
            child: ScaleTransition(
              scale: _scaleAnimation,
              alignment: Alignment.bottomLeft, // Open from bottom left
              child: _buildQuickActionsMenu(isDark),
            ),
          ),
        ],
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
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.primaryColor.withValues(alpha: 0.2),
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
                        widget.onItemSelected(5); // open in content area
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
                        setState(() => _isEditingBook = false);
                        widget.onItemSelected(7); // Show in content area
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
                        widget.onItemSelected(19);
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
    return _HoverableMenuItem(
      onTap: onTap,
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: context.primaryColor, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textLightPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebContent(BuildContext context, bool isDark) {
    return Stack(
      children: [
        // Content - IndexedStack keeps all pages alive
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.only(top: 80), // Header height
            child: widget.isAdmin
                ? IndexedStack(
                    index: widget.selectedIndex,
                    children: [
                      const AdminHomeTab(), // 0 Ana Sayfa
                      const AdminStatsTab(), // 1 İstatistikler
                      AdminUsersTab(
                        key: ValueKey('admin_users_$_adminUsersReloadKey'),
                        onUserSelected: (uid) {
                          setState(() => _selectedUserUid = uid);
                          widget.onItemSelected(4);
                        },
                      ), // 2 Kullanıcılar
                      const ProfileScreen(showHeader: true), // 3 Profil
                      _selectedUserUid == null
                          ? const SizedBox.shrink()
                          : AdminUserDetailScreen(
                              key: ValueKey('detail_$_selectedUserUid'),
                              uid: _selectedUserUid!,
                              onBack: () => widget.onItemSelected(2),
                              onChanged: () =>
                                  setState(() => _adminUsersReloadKey++),
                            ), // 4 Kullanıcı Detayı
                      AdminAddUserScreen(
                        onBack: () => widget.onItemSelected(2),
                        onChanged: () =>
                            setState(() => _adminUsersReloadKey++),
                      ), // 5 Kullanıcı Ekle
                    ],
                  )
                : IndexedStack(
                    index: widget.selectedIndex,
                    children: [
                      _buildDashboardContent(context, isDark), // 0
                      _buildBooksPage(context), // 1
                      _buildListsPage(context), // 2
                      _buildProfilePage(context), // 3
                      EditProfileScreen(
                        onBack: () => widget.onItemSelected(3),
                      ), // 4
                      _buildBookDetailPage(context), // 5
                      _buildListDetailPage(context), // 6
                      _buildAddBookPage(context), // 7
                      ChangePasswordScreen(
                        onBack: () => widget.onItemSelected(3),
                      ), // 8
                      _buildLibrariesPage(context), // 9
                      _buildLibraryDetailPage(context), // 10
                      PrivacySecurityScreen(
                        onNavigate: widget.onItemSelected,
                      ), // 11
                      _buildPrivacyPolicyPage(context), // 12
                      _buildTermsOfUsePage(context), // 13
                      AboutScreen(onBack: () => widget.onItemSelected(3)), // 14
                      HelpCenterScreen(
                        onBack: () => widget.onItemSelected(3),
                      ), // 15
                      NotificationsScreen(
                        onBack: () => widget.onItemSelected(3),
                      ), // 16
                      _buildShoppingListPage(context), // 17
                      _buildShoppingItemDetailPage(context), // 18
                      AddShoppingItemScreen(
                        onBack: () => widget.onItemSelected(17),
                      ), // 19
                    ],
                  ),
          ),
        ),
        // Glass Header - positioned on top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildPersistentHeader(
            context,
            isDark,
            _getPageTitle(widget.selectedIndex),
          ),
        ),
      ],
    );
  }

  String _getPageTitle(int index) {
    if (widget.isAdmin) {
      const adminTitles = {
        0: "Ana Sayfa",
        1: "İstatistikler",
        2: "Kullanıcılar",
        3: "Hesabım",
        4: "Kullanıcı Detayı",
        5: "Kullanıcı Ekle",
      };
      return adminTitles[index] ?? "Yönetim";
    }
    final pageTitles = {
      0: "Ana Sayfa",
      1: "Kitaplar",
      2: "Listeler",
      3: "Hesabım",
      4: "Profili Düzenle",
      5: "Kitap Detayı",
      6: "Liste Detayı",
      7: "Kitap Ekle",
      8: "Şifre Değiştir",
      9: "Kütüphanelerim",
      10: "Kütüphane Detayı",
      16: "Bildirimler",
      17: "Alışveriş Listem",
      18: "Alışveriş Detayı",
      19: "Alışveriş Listesine Ekle",
    };
    return pageTitles[index] ?? "Sayfa";
  }

  Widget _buildBooksPage(BuildContext context) {
    return BooksScreen(
      showHeader: true,
      onBookSelected: (book) {
        setState(() => _selectedBook = book);
        widget.onItemSelected(5);
      },
    );
  }

  Widget _buildListsPage(BuildContext context) {
    return ListsScreen(
      showHeader: true,
      onListSelected: (list) {
        setState(() => _selectedList = list);
        widget.onItemSelected(6);
      },
      onNavigateToShopping: () => widget.onItemSelected(17),
    );
  }

  Widget _buildProfilePage(BuildContext context) {
    return ProfileScreen(
      showHeader: true,
      onNavigateToEdit: () => widget.onItemSelected(4),
      onNavigateToPassword: () => widget.onItemSelected(8),
      onNavigateToLibraries: () => widget.onItemSelected(9),
      onNavigateToAbout: () => widget.onItemSelected(14),
      onNavigateToHelp: () => widget.onItemSelected(15),
      onNavigateToPrivacy: () => widget.onItemSelected(11),
      onNavigateToNotifications: () => widget.onItemSelected(16),
      onNavigateToShopping: () => widget.onItemSelected(17),
    );
  }

  Widget _buildBookDetailPage(BuildContext context) {
    if (_selectedBook == null) return const SizedBox();
    return BookDetailScreen(
      key: ValueKey('book_${_selectedBook!.id}'),
      book: _selectedBook!,
      onBack: () => widget.onItemSelected(1),
      onEdit: (book) {
        setState(() {
          _selectedBook = book;
          _isEditingBook = true;
        });
        widget.onItemSelected(7);
      },
    );
  }

  Widget _buildListDetailPage(BuildContext context) {
    if (_selectedList == null) return const SizedBox();
    return ListDetailScreen(
      key: ValueKey('list_${_selectedList!.id}'),
      list: _selectedList!,
      onBack: () => widget.onItemSelected(2),
      onBookSelected: (book) {
        setState(() => _selectedBook = book);
        widget.onItemSelected(5);
      },
    );
  }

  Widget _buildAddBookPage(BuildContext context) {
    final editingBook = _isEditingBook ? _selectedBook : null;
    return AddBookScreen(
      key: ValueKey('add_book_${editingBook?.id ?? 'new'}_$_isEditingBook'),
      bookToEdit: editingBook,
      onBack: () {
        setState(() => _isEditingBook = false);
        widget.onItemSelected(1);
      },
    );
  }

  Widget _buildLibrariesPage(BuildContext context) {
    return LibrariesScreen(
      showHeader: true,
      onLibrarySelected: (library) {
        setState(() => _selectedLibrary = library);
        widget.onItemSelected(10);
      },
    );
  }

  Widget _buildLibraryDetailPage(BuildContext context) {
    if (_selectedLibrary == null) return const SizedBox();
    return LibraryDetailScreen(
      key: ValueKey('lib_${_selectedLibrary!.id}'),
      library: _selectedLibrary!,
      onBack: () => widget.onItemSelected(9),
      onBookSelected: (book) {
        setState(() => _selectedBook = book);
        widget.onItemSelected(5);
      },
    );
  }

  Widget _buildPrivacyPolicyPage(BuildContext context) {
    return TextContentScreen(
      title: "Gizlilik Politikası",
      content: kPrivacyPolicyText,
      onBack: () => widget.onItemSelected(11),
    );
  }

  Widget _buildTermsOfUsePage(BuildContext context) {
    return TextContentScreen(
      title: "Kullanım Koşulları",
      content: kTermsOfUseText,
      onBack: () => widget.onItemSelected(11),
    );
  }

  Widget _buildShoppingListPage(BuildContext context) {
    return ShoppingListScreen(
      showHeader: true,
      onItemSelected: (item) {
        setState(() => _selectedShoppingItem = item);
        widget.onItemSelected(18);
      },
      onNavigateToAdd: () => widget.onItemSelected(19),
    );
  }

  Widget _buildShoppingItemDetailPage(BuildContext context) {
    if (_selectedShoppingItem == null) return const SizedBox();
    return ShoppingItemDetailScreen(
      key: ValueKey('shopping_${_selectedShoppingItem!.id}'),
      item: _selectedShoppingItem!,
      onBack: () => widget.onItemSelected(17),
      onPurchased: () => widget.onItemSelected(17),
    );
  }

  Widget _buildPersistentHeader(
    BuildContext context,
    bool isDark,
    String title,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              height: 80, // Fixed height header
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          context.surfaceColor.withValues(alpha: 0.5),
                          context.surfaceColor.withValues(alpha: 0.65),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.5),
                          Colors.white.withValues(alpha: 0.7),
                        ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: context.primaryBorder.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Sidebar Toggle
                  GestureDetector(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        PhosphorIconsRegular.sidebarSimple,
                        size: 20,
                        color: isDark
                            ? Colors.white
                            : AppColors.textLightPrimary,
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Search Bar — books/lists search is meaningless for admins
                  // (they manage users, not content), so hide it for them.
                  // Admins search users inside the Kullanıcılar tab.
                  if (widget.isAdmin)
                    const Expanded(child: SizedBox())
                  else
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 400,
                            minWidth: 150,
                          ),
                          child: const UniversalSearchField(
                            width: double.infinity,
                            hintText: "Kitap, Yazar, Liste Ara...",
                          ),
                        ),
                      ),
                    ),

                  // Theme Toggle
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeNotifier,
                    builder: (context, mode, child) {
                      final isDarkLocal =
                          mode == ThemeMode.dark ||
                          (mode == ThemeMode.system &&
                              MediaQuery.of(context).platformBrightness ==
                                  Brightness.dark);
                      return GestureDetector(
                        onTap: () async {
                          // Toggle between light and dark/black theme
                          final newMode = isDarkLocal
                              ? ThemeMode.light
                              : ThemeMode.dark;
                          themeNotifier.value = newMode;

                          // If switching to dark, keep current blackThemeNotifier value
                          // If it was never set, default to blackTheme if preferred
                          final prefs = await PreferencesService.getInstance();
                          await prefs.setThemeMode(newMode.index);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDarkLocal
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDarkLocal
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : Colors.black.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            isDarkLocal
                                ? PhosphorIconsRegular.sun
                                : PhosphorIconsRegular.moon,
                            size: 20,
                            color: isDarkLocal
                                ? Colors.white
                                : AppColors.textLightPrimary,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDashboardContent(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: HomeBody(
        onBookSelected: (book) {
          setState(() => _selectedBook = book);
          widget.onItemSelected(5);
        },
      ),
    );
  }
}

/// Hoverable menu item with background color change on hover
class _HoverableMenuItem extends StatefulWidget {
  final VoidCallback onTap;
  final bool isDark;
  final Widget child;

  const _HoverableMenuItem({
    required this.onTap,
    required this.isDark,
    required this.child,
  });

  @override
  State<_HoverableMenuItem> createState() => _HoverableMenuItemState();
}

class _HoverableMenuItemState extends State<_HoverableMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _isHovered
                ? (widget.isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
