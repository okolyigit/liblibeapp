import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/theme.dart';
import '../utils/book_filter_logic.dart';
import '../widgets/book_filter_widget.dart';
import '../widgets/filter_chips_row.dart';
import '../widgets/standard_book_card.dart';
import '../widgets/app_notification.dart';
import '../widgets/share_library_bottom_sheet.dart';
import '../widgets/glass_dialog.dart';
import '../widgets/neon_gradient_button.dart';
import '../models/book.dart';
import '../models/library.dart';
import 'book_detail.dart';
import '../services/book_service.dart';
import '../services/excel_service.dart';
import '../services/auth_service.dart';
import '../services/library_service.dart';
import '../widgets/import_excel_sheet.dart';
import '../widgets/expandable_search_icon.dart';
import '../widgets/app_back_button.dart';
import '../widgets/app_image.dart';
import '../widgets/app_header.dart';


class LibraryDetailScreen extends StatefulWidget {
  final Library library;
  final VoidCallback? onBack;
  final Function(Book)? onBookSelected;

  const LibraryDetailScreen({
    super.key,
    required this.library,
    this.onBack,
    this.onBookSelected,
  });

  @override
  State<LibraryDetailScreen> createState() => _LibraryDetailScreenState();
}

class _LibraryDetailScreenState extends State<LibraryDetailScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedBookIds = {};
  bool _isGridView = true;
  BookFilterState _filterState = const BookFilterState();
  final ScrollController _scrollController = ScrollController();
  Stream<List<Book>>? _booksStream;

  @override
  void initState() {
    super.initState();
    _booksStream = BookService().getLibraryBooks(widget.library.id);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Helper to filter fetched books
  List<Book> _filterBooks(List<Book> books) {
    return applyFilters(books, _filterState);
  }

  Future<void> _deleteSelectedBooks() async {
    if (_selectedBookIds.isEmpty) return;

    final confirm = await showGlassConfirmDialog(
      context: context,
      title: 'Seçili Kitapları Sil',
      message: '${_selectedBookIds.length} kitabı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
      icon: PhosphorIconsRegular.trash,
      confirmText: 'Hepsini Sil',
      isDestructive: true,
    );

    if (confirm != true || !mounted) return;

    try {
      // In a real app, you might want to show a loading indicator
      for (final bookId in _selectedBookIds) {
        await BookService().deleteBook(bookId);
      }

      if (mounted) {
        AppNotification.success(context, 'Kitaplar başarıyla silindi');
        setState(() {
          _isSelectionMode = false;
          _selectedBookIds.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        AppNotification.error(
          context,
          'Silme işlemi sırasında hata oluştu: $e',
        );
      }
    }
  }

  // --- Add new method here ---
  Future<void> _leaveLibrary() async {
    final confirm = await showGlassConfirmDialog(
      context: context,
      title: 'Kütüphaneden Ayrıl',
      message: 'Bu kütüphaneden çıkmak istediğinize emin misiniz? Artık bu kütüphanedeki kitapları göremeyeceksiniz ve bu kütüphanedeki ilerleme kayıtlarınız silinecek.',
      icon: PhosphorIconsRegular.signOut,
      confirmText: 'Ayrıl',
      isDestructive: true,
    );

    if (confirm != true) return;

    try {
      final userId = AuthService().currentUser?.uid;
      if (userId == null) return;

      // 1. Get all book IDs in this library
      final booksSnapshot = await FirebaseFirestore.instance
          .collection('books')
          .where('libraryId', isEqualTo: widget.library.id)
          .get();

      final bookIds = booksSnapshot.docs.map((d) => d.id).toList();

      // 2. Delete user's book_progress for these books
      final batch = FirebaseFirestore.instance.batch();
      for (final bookId in bookIds) {
        final progressRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('book_progress')
            .doc(bookId);
        batch.delete(progressRef);
      }
      await batch.commit();

      // 3. Remove user from library members
      await LibraryService().removeMember(widget.library.id, userId);

      if (mounted) {
        AppNotification.success(context, 'Kütüphaneden ayrıldınız');
        if (widget.onBack != null) {
          widget.onBack!();
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        AppNotification.error(context, 'Hata: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final currentUserId = AuthService().currentUser?.uid;
    final isOwner = widget.library.ownerId == currentUserId;
    return Builder(
      builder: (context) {
        return Scaffold(
          backgroundColor: context.themeBackground,
          body: StreamBuilder<List<Book>>(
            stream: _booksStream,
            builder: (context, snapshot) {
                // Loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Error state
                if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
                }

                final allBooks = snapshot.data ?? [];
                final displayBooks = _filterBooks(allBooks);

                // Dynamic header height calculation
                final hasStats = allBooks.isNotEmpty;
                final hasFilters = _filterState.hasActiveFilters;

                // Base header (title row + button row) is roughly 116px
                // Stats bar adds ~32px
                // Filter chips add ~44px
                double currentHeaderHeight = 116.0;
                if (hasStats) currentHeaderHeight += 32.0;
                if (hasFilters) currentHeaderHeight += 44.0;
                final statusBarTop = AppHeader.statusBarHeight(context);

                return Stack(
                  children: [
                    // Scrollable content using Slivers
                    Positioned.fill(
                      child: SafeArea(
                        top: false,
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            // Top padding for header (includes status bar)
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height: currentHeaderHeight + statusBarTop + 8,
                              ),
                            ),
                        // Books content
                        if (displayBooks.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildEmptyState(isDark),
                          )
                        else if (_isGridView)
                          _buildSliverGridView(displayBooks)
                        else
                          _buildSliverListView(displayBooks),
                        // Bottom padding
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 120),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Fixed glass header
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _isSelectionMode
                          ? AppHeader(
                              scrollController: _scrollController,
                              leading: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _isSelectionMode = false;
                                    _selectedBookIds.clear();
                                  });
                                },
                                icon: Icon(
                                  PhosphorIconsRegular.x,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textLightPrimary,
                                ),
                              ),
                              title:
                                  '${_selectedBookIds.length} kitap seçildi',
                              titleSize: 16,
                            )
                          : AppHeader(
                              scrollController: _scrollController,
                              leading: AppBackButton(
                                onPressed: () {
                                  if (widget.onBack != null) {
                                    widget.onBack!();
                                  } else {
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                              titleWidget: _buildLibraryTitle(isDark, isOwner),
                              actions: const [
                                ExpandableSearchIcon(
                                  hintText: 'Kitap veya yazar ara...',
                                ),
                              ],
                              bottom: _buildHeaderBottom(
                                isDark,
                                allBooks,
                                isOwner,
                              ),
                            ),
                    ),
                    if (_isSelectionMode)
                      Positioned(
                        left: 24,
                        right: 24,
                        bottom: 32,
                        child: _buildSelectionActionPanel(isDark),
                      ),
                  ],
                );
            },
          ),
        );
      },
    );
  }

  Widget _buildLibraryTitle(bool isDark, bool isOwner) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.primaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getIcon(widget.library.icon),
            color: context.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.library.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textLightPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (!isOwner)
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.library.ownerId)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final ownerName =
                          snapshot.data!.get('displayName') as String? ??
                          snapshot.data!.get('email') as String? ??
                          'Kütüphane Sahibi';
                      return Text(
                        ownerName,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textLightSecondary,
                        ),
                      );
                    }
                    return Text(
                      'Yükleniyor...',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textDarkSecondary
                            : AppColors.textLightSecondary,
                      ),
                    );
                  },
                )
              else if (widget.library.description != null &&
                  widget.library.description!.isNotEmpty)
                Text(
                  widget.library.description!,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textDarkSecondary
                        : AppColors.textLightSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderBottom(bool isDark, List<Book> books, bool isOwner) {
    final displayBooks = _filterBooks(books);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: PhosphorIconsRegular.funnel,
                label: 'Filtrele (${displayBooks.length})',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => BookFilterSheetContent(
                      filterState: _filterState,
                      onFilterChanged: (newState) {
                        setState(() => _filterState = newState);
                      },
                      availableBooks: books,
                    ),
                  );
                },
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                icon: PhosphorIconsRegular.sortAscending,
                label: 'Sırala',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (context) => _buildSortBottomSheet(isDark),
                  );
                },
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _isGridView = !_isGridView),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.subtleTint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
                child: Center(
                  child: Icon(
                    _isGridView
                        ? PhosphorIconsRegular.rows
                        : PhosphorIconsRegular.squaresFour,
                    size: 20,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.black54,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            _buildPopupMenu(isDark, books),
          ],
        ),
        if (books.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildStatsBar(isDark, books),
        ],
        if (_filterState.hasActiveFilters) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: FilterChipsRow(
              filterState: _filterState,
              onFilterChanged: (state) => setState(() => _filterState = state),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ],
    );
  }

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'heart':
        return PhosphorIconsFill.heart;
      case 'star':
        return PhosphorIconsFill.star;
      case 'books':
        return PhosphorIconsFill.books;
      case 'bookmark':
        return PhosphorIconsFill.bookmark;
      case 'folder':
        return PhosphorIconsFill.folder;
      case 'briefcase':
        return PhosphorIconsFill.briefcase;
      case 'graduationCap':
        return PhosphorIconsFill.graduationCap;
      default:
        return PhosphorIconsFill.books;
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isDark ? Colors.white60 : Colors.black45,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupMenu(bool isDark, List<Book> books) {
    return PopupMenuButton<String>(
      icon: Icon(
        PhosphorIconsRegular.dotsThreeVertical,
        color: isDark ? Colors.white60 : Colors.black45,
      ),
      color: context.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : context.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      elevation: 8,
      onSelected: (value) {
        if (value == 'select_books') {
          setState(() => _isSelectionMode = true);
        } else if (value == 'import_excel') {
          _showImportSheet(books);
        } else if (value == 'export_excel') {
          _exportToExcel(books);
        } else if (value == 'share_library') {
          showShareLibraryBottomSheet(
            context: context,
            library: widget.library,
          );
        } else if (value == 'leave_library') {
          _leaveLibrary();
        }
      },
      itemBuilder: (context) {
        final currentUserId = AuthService().currentUser?.uid;
        final isOwner = widget.library.ownerId == currentUserId;

        final items = <PopupMenuEntry<String>>[];

        if (isOwner) {
          items.add(
            _buildPopupItem(
              'share_library',
              PhosphorIconsRegular.userPlus,
              'Kütüphaneyi Paylaş',
              context.primaryColor,
              isDark,
            ),
          );
          items.add(
            _buildPopupItem(
              'select_books',
              PhosphorIconsRegular.checkCircle,
              'Kitap Seç / Sil',
              Colors.orange,
              isDark,
            ),
          );
          items.add(
            _buildPopupItem(
              'import_excel',
              PhosphorIconsRegular.fileArrowDown,
              'Excel ile İçe Aktar',
              context.primaryColor,
              isDark,
            ),
          );
        }

        // Everyone can export (or view)
        items.add(
          _buildPopupItem(
            'export_excel',
            PhosphorIconsRegular.export,
            'Excel\'e Dışa Aktar',
            AppColors.purple,
            isDark,
          ),
        );

        // Leave Library option for guests (non-owners)
        if (!isOwner) {
          items.add(
            _buildPopupItem(
              'leave_library',
              PhosphorIconsRegular.signOut,
              'Kütüphaneden Çık',
              Colors.red,
              isDark,
            ),
          );
        }

        return items;
      },
    );
  }

  Widget _buildSortBottomSheet(bool isDark) {
    final sortOptions = [
      {
        'key': 'title_asc',
        'label': 'Başlık (A -> Z)',
        'icon': PhosphorIconsRegular.sortAscending,
      },
      {
        'key': 'title_desc',
        'label': 'Başlık (Z -> A)',
        'icon': PhosphorIconsRegular.sortDescending,
      },
      {
        'key': 'author_asc',
        'label': 'Yazar Adı (A -> Z)',
        'icon': PhosphorIconsRegular.user,
      },
      {
        'key': 'author_desc',
        'label': 'Yazar Adı (Z -> A)',
        'icon': PhosphorIconsRegular.userSwitch,
      },
      {
        'key': 'publish_asc',
        'label': 'Basım Tarihi (Eskiden Yeniye)',
        'icon': PhosphorIconsRegular.calendarPlus,
      },
      {
        'key': 'publish_desc',
        'label': 'Basım Tarihi (Yeniden Eskiye)',
        'icon': PhosphorIconsRegular.calendarMinus,
      },
      {
        'key': 'added_asc',
        'label': 'Eklenme Tarihi (Eskiden Yeniye)',
        'icon': PhosphorIconsRegular.clockCounterClockwise,
      },
      {
        'key': 'added_desc',
        'label': 'Eklenme Tarihi (Yeniden Eskiye)',
        'icon': PhosphorIconsRegular.clock,
      },
      {'key': 'rating', 'label': 'Puan', 'icon': PhosphorIconsRegular.star},
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      Theme.of(
                        context,
                      ).scaffoldBackgroundColor.withValues(alpha: 0.8),
                      Theme.of(
                        context,
                      ).scaffoldBackgroundColor.withValues(alpha: 0.95),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.75),
                      Colors.white.withValues(alpha: 0.9),
                    ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        'Sıralama',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : AppColors.textLightPrimary,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            PhosphorIconsRegular.x,
                            size: 24,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...sortOptions.map((option) {
                  final isSelected = _filterState.sortBy == option['key'];
                  return ListTile(
                    leading: Icon(
                      option['icon'] as IconData,
                      color: isSelected
                          ? context.primaryColor
                          : (isDark ? Colors.white60 : Colors.black54),
                    ),
                    title: Text(
                      option['label'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? context.primaryColor
                            : (isDark
                                  ? Colors.white
                                  : AppColors.textLightPrimary),
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            PhosphorIconsFill.checkCircle,
                            color: context.primaryColor,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _filterState = _filterState.copyWith(
                          sortBy: option['key'] as String,
                        );
                      });
                      Navigator.pop(context);
                    },
                  );
                }),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(
    String value,
    IconData icon,
    String label,
    Color color,
    bool isDark,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
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
    );
  }

  Widget _buildStatsBar(bool isDark, List<Book> books) {
    if (books.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text(
            '${_filterBooks(books).length} kitap',
            style: TextStyle(
              color: isDark
                  ? AppColors.textDarkSecondary
                  : AppColors.textLightSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildSelectionActionPanel(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? context.surfaceColor.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : context.primaryColor.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = false;
                      _selectedBookIds.clear();
                    });
                  },
                  child: Text(
                    'Vazgeç',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white70
                          : AppColors.textLightSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: NeonGradientButton(
                  text: _selectedBookIds.isEmpty
                      ? 'Kitap Seçin'
                      : '${_selectedBookIds.length} Kitabı Sil',
                  isDestructive: true,
                  onPressed: _selectedBookIds.isEmpty
                      ? () {}
                      : _deleteSelectedBooks,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIconsRegular.books,
            size: 64,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          const SizedBox(height: 16),
          Text(
            _filterState.hasActiveFilters
                ? 'Filtreye uygun kitap bulunamadı'
                : 'Bu kütüphanede henüz kitap yok',
            style: TextStyle(
              fontSize: 16,
              color: isDark
                  ? AppColors.textDarkSecondary
                  : AppColors.textLightSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverGridView(List<Book> books) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        const padding = EdgeInsets.symmetric(horizontal: 12);
        const spacing = 12.0;

        final double availableWidth =
            constraints.crossAxisExtent - padding.horizontal;
        int crossAxisCount = (availableWidth / 200).ceil();
        if (crossAxisCount < 2) crossAxisCount = 2;

        final itemWidth =
            (availableWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;
        final coverHeight = itemWidth / StandardBookCard.coverAspectRatio;
        final itemHeight = coverHeight + StandardBookCard.metaHeight + 6;

        return SliverPadding(
          padding: padding,
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              mainAxisExtent: itemHeight,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildGridCard(books[index]),
              childCount: books.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSliverListView(List<Book> books) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildListCard(books[index]),
          ),
          childCount: books.length,
        ),
      ),
    );
  }

  Widget _buildGridCard(Book book) {
    final isSelected = _selectedBookIds.contains(book.id);

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: StandardBookCard(
            book: book,
            onTap: () {
              if (_isSelectionMode) {
                setState(() {
                  if (isSelected) {
                    _selectedBookIds.remove(book.id);
                  } else {
                    _selectedBookIds.add(book.id);
                  }
                });
              } else {
                if (widget.onBookSelected != null) {
                  widget.onBookSelected!(book);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookDetailScreen(book: book),
                    ),
                  );
                }
              }
            },
            onLongPress: () {
              final currentUserId = AuthService().currentUser?.uid;
              final isOwner = widget.library.ownerId == currentUserId;

              if (!_isSelectionMode && isOwner) {
                setState(() {
                  _isSelectionMode = true;
                  _selectedBookIds.add(book.id);
                });
              }
            },
          ),
        ),
        if (_isSelectionMode)
          Positioned(
            top: 8,
            right: 8,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected ? context.primaryColor : Colors.black38,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  PhosphorIconsBold.check,
                  size: 14,
                  color: isSelected ? Colors.white : Colors.transparent,
                ),
              ),
            ),
          ),
        if (isSelected)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.primaryColor, width: 3),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildListCard(Book book) {
    final isDark = context.isDark;
    final isSelected = _selectedBookIds.contains(book.id);

    return InkWell(
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            if (isSelected) {
              _selectedBookIds.remove(book.id);
            } else {
              _selectedBookIds.add(book.id);
            }
          });
        } else {
          if (widget.onBookSelected != null) {
            widget.onBookSelected!(book);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookDetailScreen(book: book),
              ),
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? context.subtleTint
                  : (isDark
                        ? context.surfaceColor.withValues(alpha: 0.3)
                        : Colors.white),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? context.primaryColor
                    : context.primaryColor.withValues(
                        alpha: isDark ? 0.2 : 0.4,
                      ),
                width: isSelected ? 2 : 1.5,
              ),
            ),
            child: Row(
              children: [
                if (_isSelectionMode) ...[
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.primaryColor
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? context.primaryColor : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            PhosphorIconsBold.check,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                ],
                // Book Cover
                Container(
                  width: 60,
                  height: 85,
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: book.coverUrl != null
                        ? AppImage(
                            imageUrl: book.coverUrl,
                            width: 60,
                            height: 85,
                            fit: BoxFit.cover,
                            errorWidget: Container(
                              color: Colors.grey[300],
                              child: Icon(
                                PhosphorIconsRegular.imageBroken,
                                color: Colors.grey[600],
                              ),
                            ),
                          )
                        : Container(
                            color: context.surfaceColor,
                            child: Icon(
                              PhosphorIconsRegular.image,
                              color: context.primaryColor.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                // Book Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : AppColors.textLightPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.author,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textLightSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Status removed
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  void _showImportSheet(List<Book> existingBooks) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ImportExcelSheet(
        libraryId: widget.library.id,
        currentBooks: existingBooks,
        onSuccess: () {
          // Refresh triggered automatically by StreamBuilder
        },
      ),
    );
  }

  Future<void> _exportToExcel(List<Book> books) async {
    try {
      final filteredBooks = _filterBooks(books);
      final bytes = await ExcelService().generateExcel(filteredBooks);

      if (bytes == null) {
        if (mounted) {
          AppNotification.error(context, 'Excel oluşturulamadı');
        }
        return;
      }

      final fileName =
          '${widget.library.name.replaceAll(' ', '_')}_export.xlsx';
      await ExcelService().saveAndShareFile(fileName, bytes);

      if (mounted) {
        AppNotification.success(context, 'Excel dosyası paylaşıldı');
      }
    } catch (e) {
      if (mounted) {
        AppNotification.error(context, 'Hata: $e');
      }
    }
  }
}
