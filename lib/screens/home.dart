import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/expandable_search_icon.dart';
import '../widgets/standard_book_card.dart';
import '../widgets/web_book_carousel.dart';
import '../widgets/migration_dialog.dart';
import '../widgets/app_header.dart';
import 'books.dart';
import 'lists.dart';
import 'profile_screen.dart';
import 'admin/tabs/admin_home_tab.dart';
import 'admin/tabs/admin_stats_tab.dart';
import 'admin/tabs/admin_users_tab.dart';
import '../providers/app_data_provider.dart';
import '../widgets/neon_gradient_button.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../models/shopping_item.dart';
import '../services/shopping_service.dart';
import '../screens/shopping_item_detail.dart';

class HomeScreen extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isAdmin;

  const HomeScreen({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isAdmin = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _isKeyboardVisible = false;
  bool _isMenuOpen = false;
  final GlobalKey<FloatingNavBarState> _navBarKey =
      GlobalKey<FloatingNavBarState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Check for migration after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        MigrationHelper.checkAndShowMigrationDialog(context);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = WidgetsBinding
        .instance
        .platformDispatcher
        .views
        .first
        .viewInsets
        .bottom;
    final isKeyboardVisible = bottomInset > 0;
    if (_isKeyboardVisible != isKeyboardVisible) {
      setState(() {
        _isKeyboardVisible = isKeyboardVisible;
      });
    }
  }

  void _onMenuStateChanged(bool isOpen) {
    setState(() {
      _isMenuOpen = isOpen;
    });
  }

  void _closeMenu() {
    _navBarKey.currentState?.closeMenu();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Page Content
          _buildPageContent(),

          // Dismiss layer when menu is open
          if (_isMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeMenu,
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),
            ),

          // Floating NavBar
          if (!_isKeyboardVisible)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: FloatingNavBar(
                  key: _navBarKey,
                  selectedIndex: widget.selectedIndex,
                  onItemSelected: widget.onItemSelected,
                  onMenuStateChanged: _onMenuStateChanged,
                  isAdmin: widget.isAdmin,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPageContent() {
    return IndexedStack(
      index: widget.selectedIndex,
      children: widget.isAdmin
          ? const [
              AdminHomeTab(),
              AdminStatsTab(),
              AdminUsersTab(),
              ProfileScreen(showHeader: true),
            ]
          : const [
              HomeContent(),
              BooksScreen(),
              ListsScreen(),
              ProfileScreen(showHeader: true),
            ],
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    // Navbar height (approx 64) + margin (8*2=16) + extra spacing + system padding
    final navbarSpacing = 84 + bottomPadding;
    final isDark = context.isDark;

    // Header height (matches AppHeader content height: 48 title row + 12+12 padding = 72)
    const headerHeight = 72.0;
    final statusBarTop = AppHeader.statusBarHeight(context);

    return Stack(
      children: [
        // Scrollable content — starts at screen top, padding clears the
        // glass header (which includes the status bar region).
        Positioned.fill(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(
              12,
              headerHeight + statusBarTop + 8,
              12,
              navbarSpacing,
            ),
            child: const HomeBody(),
          ),
        ),
        // Fixed glass header — paints from y=0 (screen top) and extends
        // under the status bar via its own internal padding.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AppHeader(
            scrollController: _scrollController,
            titleWidget: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      isDark
                          ? 'assets/icon/lighticon.png'
                          : 'assets/icon/darkicon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Text(
                  "Liblibe",
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF9CCAB0)
                        : const Color(0xFF244D52),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            actions: const [
              ExpandableSearchIcon(hintText: "Kitap, Yazar, Liste Ara..."),
            ],
          ),
        ),
      ],
    );
  }
}

class HomeBody extends StatelessWidget {
  final Function(Book)? onBookSelected;

  const HomeBody({super.key, this.onBookSelected});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppDataProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(provider.errorMessage!),
                const SizedBox(height: 16),
                NeonGradientButton(
                  onPressed: () {
                    // Logic to retry could go here if needed,
                    // though currently it's empty in legacy code.
                  },
                  text: 'Tekrar Dene',
                  width: 200,
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Recently Added (Son Eklenenler)
            _buildSectionHeader(context, "Son Eklenen Kitaplar"),
            const SizedBox(height: 16),
            _buildRecentlyAddedList(context, provider.recentlyAddedBooks),

            const SizedBox(height: 32),

            // Shopping List (Alışveriş listesine yeni eklenen kitaplar)
            _buildSectionHeader(
              context,
              "Alışveriş Listesine Yeni Eklenen Kitaplar",
            ),
            const SizedBox(height: 16),
            _buildShoppingListSection(context),

            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = context.isDark;
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : AppColors.textLightPrimary,
      ),
    );
  }

  double _calculateCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double availableWidth = kIsWeb ? screenWidth - 80 : screenWidth - 24;

    int cardsToShow;
    if (kIsWeb) {
      cardsToShow = (availableWidth / 180).ceil();
      if (cardsToShow < 3) cardsToShow = 3;
    } else {
      cardsToShow = 3;
    }

    final totalSpacing = 12.0 * (cardsToShow - 1);
    return (availableWidth - totalSpacing) / cardsToShow;
  }

  Widget _buildRecentlyAddedList(BuildContext context, List<Book> books) {
    final cardWidth = _calculateCardWidth(context);
    final coverHeight = cardWidth / StandardBookCard.coverAspectRatio;
    final cardHeight = coverHeight + StandardBookCard.metaHeight + 6;

    if (books.isEmpty) {
      return _buildEmptyState(
        context,
        "Henüz kitap eklenmemiş.",
        hint: "+ butonunu kullanın",
      );
    }

    // Web: Use WebBookCarousel with frame and arrows
    if (kIsWeb) {
      return WebBookCarousel(
        books: books,
        cardWidth: cardWidth,
        onBookSelected: onBookSelected,
      );
    }

    // Mobile: Simple horizontal ListView
    return SizedBox(
      height: cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) => SizedBox(
          width: cardWidth,
          child: StandardBookCard(
            book: books[index],
            onTap: onBookSelected != null
                ? () => onBookSelected!(books[index])
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildShoppingListSection(BuildContext context) {
    return StreamBuilder<List<ShoppingItem>>(
      stream: ShoppingService().getItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return _buildEmptyState(
            context,
            "Alışveriş listesi boş.",
            hint: "+ butonunu kullanın",
          );
        }

        // Limit to 10 recently added items
        final recentItems = items.take(10).toList();

        final cardWidth = _calculateCardWidth(context);
        final coverHeight = cardWidth / StandardBookCard.coverAspectRatio;
        final cardHeight = coverHeight + StandardBookCard.metaHeight + 6;

        // Map to Book just for UI rendering
        final List<Book> dummyBooks = recentItems.map((item) {
          return Book(
            id: item.id,
            libraryId: 'shopping',
            title: item.title,
            author: item.author,
            coverUrl: item.coverUrl,
            genre: item.genre,
            addedDate: item.addedDate,
            ownerId: item.ownerId,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
          );
        }).toList();

        // Web: Use WebBookCarousel with frame and arrows
        if (kIsWeb) {
          return WebBookCarousel(
            books: dummyBooks,
            cardWidth: cardWidth,
            onBookSelected: (book) {
              final item = recentItems.firstWhere((i) => i.id == book.id);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShoppingItemDetailScreen(item: item),
                ),
              );
            },
          );
        }

        // Mobile: Simple horizontal ListView
        return SizedBox(
          height: cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: dummyBooks.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) => SizedBox(
              width: cardWidth,
              child: StandardBookCard(
                book: dummyBooks[index],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ShoppingItemDetailScreen(item: recentItems[index]),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    String message, {
    String? hint,
  }) {
    final isDark = context.isDark;
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: context.subtleTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.primaryBorder.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black45,
              fontSize: 14,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 8),
            Text(
              hint,
              style: TextStyle(
                color: isDark
                    ? Colors.white30
                    : AppColors.textLightSecondary.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
