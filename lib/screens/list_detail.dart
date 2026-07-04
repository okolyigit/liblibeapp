import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/theme.dart';
import '../utils/book_filter_logic.dart';
import '../widgets/book_filter_widget.dart';
import '../widgets/filter_chips_row.dart';
import '../widgets/standard_book_card.dart';
import '../widgets/app_notification.dart';
import '../models/book.dart';
import 'book_detail.dart';
import '../models/reading_list.dart';
import '../services/book_service.dart';
import '../services/list_service.dart';
import '../widgets/app_back_button.dart';
import '../widgets/app_image.dart';
import '../widgets/glass_dialog.dart';
import '../widgets/neon_gradient_button.dart';

class ListDetailScreen extends StatefulWidget {
  final ReadingList list;
  final VoidCallback? onBack;
  final Function(Book)? onBookSelected;

  const ListDetailScreen({
    super.key,
    required this.list,
    this.onBack,
    this.onBookSelected,
  });

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedBookIds = {};
  bool _isGridView = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  BookFilterState _filterState = const BookFilterState();

  // No longer using getter for books as we need async fetch

  // Future to fetch books with self-healing for missing items
  Future<List<Book>> _fetchBooks() async {
    if (widget.list.bookIds.isEmpty) return [];

    final books = await BookService().getBooksByIds(widget.list.bookIds);

    // Check for "ghost" books (IDs present in list but book doc missing)
    if (books.length < widget.list.bookIds.length) {
      final fetchedIds = books.map((b) => b.id).toSet();
      final missingIds = widget.list.bookIds
          .where((id) => !fetchedIds.contains(id))
          .toList();

      if (missingIds.isNotEmpty) {
        debugPrint(
          "Found ${missingIds.length} missing books in list. Cleaning up...",
        );
        // Fire and forget cleanup
        unawaited(
          ListService()
              .removeBooksFromList(widget.list.id, missingIds)
              .then((_) {
                debugPrint(
                  "Cleaned up missing books from list ${widget.list.name}",
                );
              })
              .catchError((e) {
                debugPrint("Error cleaning up list: $e");
              }),
        );
      }
    }

    return books;
  }

  // Helper to filter fetched books
  List<Book> _filterBooks(List<Book> books) {
    return applyFilters(books, _filterState);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: FutureBuilder<List<Book>>(
          future: _fetchBooks(),
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

            return Stack(
              children: [
                Column(
                  children: [
                    _buildHeader(isDark, allBooks),
                    FilterChipsRow(
                      filterState: _filterState,
                      onFilterChanged: (state) =>
                          setState(() => _filterState = state),
                    ),
                    if (_filterState.hasActiveFilters)
                      const SizedBox(height: 8),
                    _buildStatsBar(isDark, allBooks),
                    const SizedBox(height: 16),
                    Expanded(
                      child: displayBooks.isEmpty
                          ? _buildEmptyState(isDark)
                          : (_isGridView
                                ? _buildGridView(displayBooks)
                                : _buildListView(displayBooks)),
                    ),
                  ],
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
      ),
    );
  }

  Widget _buildHeader(bool isDark, List<Book> books) {
    if (_isSelectionMode) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: context.surfaceColor,
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedBookIds.clear();
                });
              },
              icon: Icon(
                PhosphorIconsRegular.x,
                color: isDark ? Colors.white : AppColors.textLightPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_selectedBookIds.length} kitap seçildi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textLightPrimary,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          AppBackButton(
            onPressed: () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          if (_isSearching)
            Expanded(
              child: Container(
                height: 44,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? context.surfaceColor.withValues(alpha: 0.5)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textLightPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Kitap veya yazar ara...',
                    hintStyle: TextStyle(
                      color: isDark
                          ? AppColors.textDarkSecondary
                          : AppColors.textLightSecondary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(PhosphorIconsRegular.x),
                      onPressed: () {
                        setState(() {
                          _isSearching = false;
                          _filterState = _filterState.copyWith(searchQuery: '');
                          _searchController.clear();
                        });
                      },
                    ),
                  ),
                  onChanged: (value) => setState(
                    () => _filterState = _filterState.copyWith(
                      searchQuery: value,
                    ),
                  ),
                ),
              ),
            )
          else ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                PhosphorIconsRegular.listBullets,
                color: context.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.list.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textLightPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.list.description != null)
                    Text(
                      widget.list.description!,
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
            IconButton(
              onPressed: () => setState(() => _isSearching = true),
              icon: Icon(
                PhosphorIconsRegular.magnifyingGlass,
                color: isDark ? Colors.white : AppColors.textLightPrimary,
              ),
            ),
            BookFilterWidget(
              filterState: _filterState,
              onFilterChanged: (state) => setState(() => _filterState = state),
              availableBooks: books,
            ),
            IconButton(
              onPressed: () => setState(() => _isGridView = !_isGridView),
              icon: Icon(
                _isGridView
                    ? PhosphorIconsRegular.rows
                    : PhosphorIconsRegular.squaresFour,
                color: isDark ? Colors.white : AppColors.textLightPrimary,
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                PhosphorIconsRegular.dotsThreeVertical,
                color: isDark ? Colors.white : AppColors.textLightPrimary,
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
                if (value == 'edit') {
                  _showEditListDialog();
                } else if (value == 'delete') {
                  _showDeleteConfirmDialog();
                } else if (value == 'remove_books') {
                  setState(() => _isSelectionMode = true);
                }
              },
              itemBuilder: (context) => [
                _buildPopupItem(
                  'remove_books',
                  PhosphorIconsRegular.minusCircle,
                  'Kitap Çıkar',
                  Colors.orange,
                  isDark,
                ),
                _buildPopupItem(
                  'edit',
                  PhosphorIconsRegular.pencilSimple,
                  'Listeyi Düzenle',
                  context.primaryColor,
                  isDark,
                ),
                _buildPopupItem(
                  'delete',
                  PhosphorIconsRegular.trash,
                  'Listeyi Sil',
                  Colors.red[400]!,
                  isDark,
                ),
              ],
            ),
          ],
        ],
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

  Future<void> _removeSelectedBooks() async {
    try {
      await ListService().removeBooksFromList(
        widget.list.id,
        _selectedBookIds.toList(),
      );

      setState(() {
        // Optimistically update local list for immediate feedback
        widget.list.bookIds.removeWhere((id) => _selectedBookIds.contains(id));
        _isSelectionMode = false;
        _selectedBookIds.clear();
      });

      if (mounted) {
        AppNotification.success(context, 'Seçilen kitaplar listeden çıkarıldı');
      }
    } catch (e) {
      if (mounted) {
        AppNotification.error(context, 'Hata: $e');
      }
    }
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
                : Colors.white.withValues(alpha: 0.95), // Near opaque
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : context.primaryColor.withValues(
                      alpha: 0.4,
                    ), // Stronger border
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
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
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
                      : '${_selectedBookIds.length} Kitabı Çıkar',
                  isDestructive: true,
                  onPressed: _selectedBookIds.isEmpty
                      ? () {}
                      : _removeSelectedBooks,
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
                : 'Bu listede henüz kitap yok',
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

  Widget _buildGridView(List<Book> books) {
    // Responsive grid columns
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount;
    if (screenWidth > 1600) {
      crossAxisCount = 8;
    } else if (screenWidth > 1300) {
      crossAxisCount = 6;
    } else if (screenWidth > 1000) {
      crossAxisCount = 5;
    } else if (screenWidth > 600) {
      crossAxisCount = 4;
    } else {
      crossAxisCount = 2;
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 120),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.58,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) => _buildGridCard(books[index]),
    );
  }

  Widget _buildListView(List<Book> books) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 120),
      itemCount: books.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildListCard(books[index]),
      ),
    );
  }

  Widget _buildGridCard(Book book) {
    final isSelected = _selectedBookIds.contains(book.id);

    return GestureDetector(
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Book card fills entire space
          Positioned.fill(
            child: StandardBookCard(book: book, onTap: () {}),
          ),
          // Selection overlay
          if (_isSelectionMode)
            Positioned(
              top: 8,
              right: 8,
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
          // Selection border overlay
          if (isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.primaryColor, width: 3),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListCard(Book book) {
    final isDark = context.isDark;
    final isSelected = _selectedBookIds.contains(book.id);

    return GestureDetector(
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
                        : Colors.white), // Opaque near opaque
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? context.primaryColor
                    : context.primaryColor.withValues(
                        alpha: isDark ? 0.2 : 0.4,
                      ), // Stronger border
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
                            errorWidget: Center(
                              child: Icon(
                                PhosphorIconsRegular.imageBroken,
                                size: 24,
                                color: isDark
                                    ? Colors.white24
                                    : Colors.black12,
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              PhosphorIconsRegular.book,
                              size: 24,
                              color: isDark ? Colors.white24 : Colors.black12,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : AppColors.textLightPrimary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.author,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textLightSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (book.rating > 0)
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < book.rating
                                  ? PhosphorIconsFill.star
                                  : PhosphorIconsRegular.star,
                              size: 14,
                              color: context.primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  PhosphorIconsRegular.caretRight,
                  color: isDark
                      ? AppColors.textDarkSecondary
                      : AppColors.textLightSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showEditListDialog() {
    final isDark = context.isDark;
    final nameController = TextEditingController(text: widget.list.name);
    final descController = TextEditingController(
      text: widget.list.description ?? '',
    );
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ClipRRect(
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
                          bgColor.withValues(alpha: 0.8),
                          bgColor.withValues(alpha: 0.95),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.75),
                          Colors.white.withValues(alpha: 0.9),
                        ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Title row with close button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  PhosphorIconsRegular.pencilSimple,
                                  color: context.primaryColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Listeyi Düzenle',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textLightPrimary,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.black.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 24,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Name field
                        TextField(
                          controller: nameController,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : AppColors.textLightPrimary,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Liste Adı',
                            labelStyle: TextStyle(
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textLightSecondary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: context.primaryColor,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark ? Colors.white10 : Colors.black12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Description field
                        TextField(
                          controller: descController,
                          maxLines: 2,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : AppColors.textLightPrimary,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Açıklama',
                            labelStyle: TextStyle(
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textLightSecondary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: context.primaryColor,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark ? Colors.white10 : Colors.black12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: NeonGradientButton(
                                text: 'Vazgeç',
                                onPressed: () => Navigator.pop(context),
                                isSecondary: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: NeonGradientButton(
                                text: 'Kaydet',
                                onPressed: () {
                                  Navigator.pop(context);
                                  AppNotification.success(
                                    context,
                                    'Liste güncellendi',
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
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

  Future<void> _showDeleteConfirmDialog() async {
    final confirmed = await showGlassConfirmDialog(
      context: context,
      title: 'Listeyi Sil',
      message: '"${widget.list.name}" listesini silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz.',
      icon: PhosphorIconsRegular.warning,
      confirmText: 'Sil',
      isDestructive: true,
    );

    if (confirmed == true) {
      if (!mounted) return;
      Navigator.pop(context); // Pop detail screen
      AppNotification.success(context, '"${widget.list.name}" silindi');
    }
  }
}
