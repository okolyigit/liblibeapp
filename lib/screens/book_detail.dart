import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/theme.dart';
import '../widgets/app_image.dart';
import '../models/reading_list.dart';
import '../models/user_book_progress.dart';
import '../widgets/create_list_bottom_sheet.dart';
import '../widgets/app_notification.dart';
import '../widgets/app_back_button.dart';
import '../services/list_service.dart';
import '../services/user_progress_service.dart';
import '../widgets/glass_dialog.dart';
import '../widgets/neon_gradient_button.dart';


import '../services/auth_service.dart';
import '../models/book.dart';
import 'package:share_plus/share_plus.dart';
import '../services/like_service.dart';
import '../services/book_service.dart';
import 'add_book_screen.dart';
import 'book_detail/widgets/book_markets_card.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;
  final VoidCallback? onBack;
  final Function(Book)? onEdit;
  const BookDetailScreen({
    super.key,
    required this.book,
    this.onBack,
    this.onEdit,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  int _rating = 0;
  late TextEditingController _notesController;
  bool _isDirty = false;
  bool _isOwner = false; // Whether current user can edit/delete this book
  UserBookProgress? _progress;

  @override
  void initState() {
    super.initState();
    final userId = AuthService().currentUser?.uid;
    _isOwner = userId != null && widget.book.ownerId == userId;

    // Initialize with book data first to prevent pop-in
    _rating = widget.book.rating;
    _notesController = TextEditingController(text: widget.book.userNotes);

    _loadUserProgress();

    _notesController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    _notesController.removeListener(_checkForChanges);
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProgress() async {
    try {
      final progress = await UserProgressService().getProgressOnce(
        widget.book.id,
      );
      if (mounted) {
        setState(() {
          _progress = progress;
          _rating = progress?.rating ?? 0;
          _notesController.text = progress?.userNotes ?? '';
        });
      }
    } catch (e) {
      debugPrint('book_detail: ilerleme yüklenemedi: $e');
    }
  }

  void _checkForChanges() {
    final hasChanges =
        _rating != (_progress?.rating ?? 0) ||
        _notesController.text != (_progress?.userNotes ?? '');

    if (hasChanges != _isDirty) {
      setState(() => _isDirty = hasChanges);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final book = widget.book;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use desktop layout for wide screens (dashboard mode)
        if (constraints.maxWidth > 900) {
          return _buildDesktopLayout(context, isDark);
        }

        // Mobile layout with SliverAppBar
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: _isDirty
              ? FloatingActionButton(
                  onPressed: _saveChanges,
                  backgroundColor: context.primaryColor,
                  foregroundColor: const Color(0xFF1D3D47),
                  elevation: 4,
                  child: const Icon(PhosphorIconsBold.check, size: 28),
                )
              : null,
          body: CustomScrollView(
            slivers: [
              // App Bar with Cover
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                backgroundColor: Colors.transparent,
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.black : Colors.white)
                              .withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          PhosphorIconsRegular.listBullets,
                          color: isDark
                              ? Colors.white
                              : AppColors.textLightPrimary,
                        ),
                      ),
                      onPressed: () => _showAddToListSheet(),
                    ),
                  ),
                ],
                leading: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AppBackButton(
                      onPressed: () {
                        if (widget.onBack != null) {
                          widget.onBack!();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Centered Large Book Cover Background
                      Container(color: context.themeBackground),

                      // Centered Large Book Cover
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 40, bottom: 20),
                          child: Container(
                            width: 200,
                            height: 300,
                            decoration: BoxDecoration(
                              color: context.subtleTint,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: context.primaryBorder,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: book.coverUrl != null
                                  ? AppImage(
                                      imageUrl: book.coverUrl,
                                      fit: BoxFit.cover,
                                      highQuality: true,
                                      placeholder: Container(
                                        color: isDark
                                            ? context.surfaceColor
                                            : Colors.grey[300],
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: context.primaryColor,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                      errorWidget: Container(
                                        color: isDark
                                            ? context.surfaceColor
                                            : Colors.grey[300],
                                        child: Center(
                                          child: Icon(
                                            PhosphorIconsRegular.imageBroken,
                                            size: 48,
                                            color: isDark
                                                ? Colors.white24
                                                : Colors.black12,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: isDark
                                          ? context.surfaceColor
                                          : Colors.grey[300],
                                      child: Center(
                                        child: Icon(
                                          PhosphorIconsRegular.book,
                                          size: 48,
                                          color: isDark
                                              ? Colors.white24
                                              : Colors.black12,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),

                      // Action Buttons Column (Right aligned)
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Delete Button - Only show for library owner
                            if (_isOwner) ...[
                              _buildCoverActionButton(
                                context,
                                icon: PhosphorIconsRegular.trash,
                                onTap: () => _showDeleteDialog(context),
                                isDark: isDark,
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Heart Button (Favorite) - Top
                            _buildHeartButton(isDark),
                            const SizedBox(height: 12),

                            // Share Button
                            _buildCoverActionButton(
                              context,
                              icon: PhosphorIconsRegular.shareNetwork,
                              onTap: () {
                                String? url = widget.book.previewLink;
                                if (url == null && widget.book.isbn != null) {
                                  url =
                                      'https://books.google.com/books?vid=ISBN${widget.book.isbn}';
                                }
                                final text =
                                    "Bu kitaba bir göz at: ${widget.book.title} - ${widget.book.author}\n${url ?? ''}";
                                Share.share(text, subject: widget.book.title);
                              },
                              isDark: isDark,
                            ),

                            // Edit Button - Only show for library owner
                            if (_isOwner) ...[
                              const SizedBox(height: 12),
                              _buildCoverActionButton(
                                context,
                                icon: PhosphorIconsRegular.pencilSimple,
                                onTap: () async {
                                  final result = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddBookScreen(
                                        bookToEdit: widget.book,
                                      ),
                                    ),
                                  );
                                  if (result == true && context.mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                                isDark: isDark,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Emerald Divider Line
              SliverToBoxAdapter(
                child: Container(
                  height: 1.5,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(1),
                    boxShadow: [
                      BoxShadow(
                        color: context.primaryColor.withValues(alpha: 0.15),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 900;
                    final isMedium =
                        constraints.maxWidth > 600 &&
                        constraints.maxWidth <= 900;

                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title & Author - Centered on wide screens
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 600),
                              child: Column(
                                children: [
                                  Text(
                                    book.title,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.textLightPrimary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    book.author,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDark
                                          ? AppColors.textDarkSecondary
                                          : AppColors.textLightSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),

                                  // Rating
                                  _buildRatingSection(isDark),
                                  const SizedBox(height: 24),

                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Description Section
                          if (book.description != null &&
                              book.description!.isNotEmpty) ...[
                            Text(
                              "Özet",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textLightPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              book.description!,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: isDark
                                    ? AppColors.textDarkSecondary
                                    : AppColors.textLightSecondary,
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],

                          // Responsive Cards Section
                          if (isWide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Progress card removed from here
                                // Expanded(child: _buildProgressCard(isDark)),
                                // const SizedBox(width: 16),
                                Expanded(child: _buildInfoCardSection(isDark)),
                                const SizedBox(width: 16),
                                Expanded(child: BookMarketsCard(book: widget.book)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildNotesCard(isDark)),
                              ],
                            )
                          else if (isMedium)
                            Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Expanded(child: _buildProgressCard(isDark)),
                                    // const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildInfoCardSection(isDark),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: BookMarketsCard(book: widget.book)),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildNotesCard(isDark)),
                                  ],
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                // _buildProgressCard(isDark),
                                // const SizedBox(height: 16),
                                _buildInfoCardSection(isDark),
                                const SizedBox(height: 16),
                                BookMarketsCard(book: widget.book),
                                const SizedBox(height: 16),
                                _buildNotesCard(isDark),
                              ],
                            ),

                          const SizedBox(height: 32),


                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRatingSection(bool isDark) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    return Row(
      mainAxisAlignment: isDesktop
          ? MainAxisAlignment.start
          : MainAxisAlignment.center,
      children: [
        ...List.generate(5, (index) {
          return GestureDetector(
            onTap: () => setState(() {
              _rating = index + 1;
              _checkForChanges();
            }),
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                index < _rating
                    ? PhosphorIconsFill.star
                    : PhosphorIconsRegular.star,
                color: context.primaryColor,
                size: 28,
              ),
            ),
          );
        }),
        if (_rating > 0) ...[
          const SizedBox(width: 8),
          Text(
            "$_rating/5",
            style: TextStyle(
              color: isDark
                  ? AppColors.textDarkSecondary
                  : AppColors.textLightSecondary,
            ),
          ),
        ],
      ],
    );
  }

  // Cover action button helper
  Widget _buildCoverActionButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? context.surfaceColor.withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : context.primaryColor.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white70 : AppColors.textLightSecondary,
          size: 22,
        ),
      ),
    );
  }

  // Heart button with favorite state
  Widget _buildHeartButton(bool isDark) {
    return StreamBuilder<bool>(
      stream: LikeService().isBookLiked(widget.book.id),
      builder: (context, snapshot) {
        final isFavorite = snapshot.data ?? false;

        return GestureDetector(
          onTap: () async {
            try {
              final newStatus = await LikeService().toggleLike(widget.book.id);
              if (context.mounted) {
                AppNotification.success(
                  context,
                  newStatus
                      ? 'Kitap Beğenilenlere eklendi'
                      : 'Kitap Beğenilenlerden çıkarıldı',
                );
              }
            } catch (e) {
              if (context.mounted) {
                AppNotification.error(context, 'Hata: $e');
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? context.surfaceColor.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              border: Border.all(
                color: isFavorite
                    ? Colors.red[400]!.withValues(alpha: 0.4)
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : context.primaryColor.withValues(alpha: 0.3)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isFavorite ? PhosphorIconsFill.heart : PhosphorIconsRegular.heart,
              color: isFavorite
                  ? Colors.red[400]
                  : (isDark ? Colors.white70 : AppColors.textLightSecondary),
              size: 22,
            ),
          ),
        );
      },
    );
  }





  // Book Info Card Section
  Widget _buildInfoCardSection(bool isDark) {
    final book = widget.book;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? context.surfaceColor.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.primaryBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Kitap Bilgileri",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textLightPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRowCompact(
            "Tür",
            book.genre,
            PhosphorIconsRegular.tag,
            isDark,
          ),

          if (book.categories.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: book.categories.map((cat) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: context.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.primaryColor,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          if (book.pageCount != null) ...[
            _buildInfoRowCompact(
              "Sayfa",
              "${book.pageCount}",
              PhosphorIconsRegular.bookOpenText,
              isDark,
            ),
            const SizedBox(height: 12),
          ],
          if (book.publisher != null) ...[
            _buildInfoRowCompact(
              "Yayınevi",
              book.publisher!,
              PhosphorIconsRegular.buildings,
              isDark,
            ),
            const SizedBox(height: 12),
          ],
          if (book.publishedDate != null) ...[
            _buildInfoRowCompact(
              "Yayın Yılı",
              book.publishedDate!.length >= 4
                  ? book.publishedDate!.substring(0, 4)
                  : book.publishedDate!,
              PhosphorIconsRegular.calendarBlank,
              isDark,
            ),
            const SizedBox(height: 12),
          ],
          if (book.isbn != null && book.isbn!.isNotEmpty) ...[
            _buildInfoRowCompact(
              "ISBN",
              book.isbn!,
              PhosphorIconsRegular.barcode,
              isDark,
            ),
            const SizedBox(height: 12),
          ],

          _buildInfoRowCompact(
            "Eklenme",
            _formatDate(book.addedDate),
            PhosphorIconsRegular.clock,
            isDark,
          ),
        ],
      ),
    );
  }

  // Compact info row for cards
  Widget _buildInfoRowCompact(
    String label,
    String value,
    IconData icon,
    bool isDark,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.primaryColor),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? AppColors.textDarkSecondary
                : AppColors.textLightSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.textLightPrimary,
          ),
        ),
      ],
    );
  }

  // Notes Card
  Widget _buildNotesCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? context.surfaceColor.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.primaryBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Notlarım",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textLightPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            maxLines: 4,
            controller: _notesController,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white : AppColors.textLightPrimary,
            ),
            decoration: InputDecoration(
              hintText: "Kitap hakkında notlarınızı yazın...",
              hintStyle: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textLightSecondary,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    try {
      // Update new user progress system
      await UserProgressService().updateProgress(
        bookId: widget.book.id,
        rating: _rating,
        userNotes: _notesController.text,
      );

      // ALSO update old embedded status field for backwards compatibility (Only if owner)
      // This ensures GlassHero stats and getRecentlyUpdatedBooks work
      if (_isOwner) {
        await BookService().updateBook(widget.book.id, {
          'rating': _rating,
          'userNotes': _notesController.text,
        });
      }

      if (mounted) {
        // Reload progress to update cached values
        final progress = await UserProgressService().getProgressOnce(
          widget.book.id,
        );
        
        if (!mounted) return;
        
        setState(() {
          _progress = progress;
          _isDirty = false;
        });
        AppNotification.success(context, 'Değişiklikler kaydedildi');
      }
    } catch (e) {
      if (mounted) {
        AppNotification.error(context, 'Hata: $e');
      }
    }
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final confirmed = await showGlassConfirmDialog(
      context: context,
      title: "Kitabı Sil",
      message: "Bu kitabı silmek istediğinize emin misiniz?",
      icon: PhosphorIconsRegular.trash,
      confirmText: "Sil",
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        await BookService().deleteBook(widget.book.id);

        if (context.mounted) {
          if (widget.onBack != null) {
            widget.onBack!();
          } else {
            Navigator.pop(context);
          }
          AppNotification.success(context, 'Kitap başarıyla silindi');
        }
      } catch (e) {
        if (context.mounted) {
          AppNotification.error(context, 'Hata: $e');
        }
      }
    }
  }


  String _formatDate(DateTime date) {
    return "${date.day}.${date.month}.${date.year}";
  }

  void _showAddToListSheet() {
    final isDark = context.isDark;
    // Note: selectedListIds would be used when implementing list selection feature

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.8,
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              PhosphorIconsRegular.listBullets,
                              color: context.primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Listelerim',
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
                          child: Icon(
                            PhosphorIconsRegular.x,
                            size: 24,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Eklemek için birden fazla liste seçebilirsiniz.',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textDarkSecondary
                            : AppColors.textLightSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: InkWell(
                      onTap: () => showCreateListBottomSheet(
                        context: context,
                        onCreated: () => setSheetState(() {}),
                      ),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: context.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              PhosphorIconsRegular.plusCircle,
                              color: context.primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Yeni liste oluştur',
                              style: TextStyle(
                                color: context.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: StreamBuilder<List<ReadingList>>(
                      stream: ListService().getUserLists(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(child: Text('Hata: ${snapshot.error}'));
                        }

                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final lists = snapshot.data ?? <ReadingList>[];

                        if (lists.isEmpty) {
                          return Center(
                            child: Text(
                              'Henüz bir listeniz yok',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                          itemCount: lists.length,
                          itemBuilder: (context, index) {
                            final list = lists[index];

                            // Check if list has book
                            final hasBook = list.bookIds.contains(
                              widget.book.id,
                            );
                            // If selectedListIds doesn't have it, but it's initially selected, add it to initial set if not modified
                            // Better approach: use a local state initialized from stream data?
                            // Since stream is async, we check if list id is in our selected set.
                            // BUT, we need to know initial state to determining additions/removals.
                            // For simplicity: checked state is managed purely by selectedListIds.
                            // We need to initialize selectedListIds with lists that ALREADY contain the book.
                            // This is tricky inside a StreamBuilder loop if we want to do it only once.
                            // Instead, we'll check list.bookIds directly if we haven't toggled it, but we need a changeset.

                            // Simplified strategy:
                            // UI shows selected if selectedListIds has it.
                            // On tap, toggle selectedListIds.
                            // "Apply" compares final selectedListIds with initial list state stream? No, stream might update.
                            // Let's rely on the user selection.

                            // Initialize selectedListIds based on data ONCE? No, StreamBuilder rebuilds.
                            // UI: check if (selectedListIds.contains(id)) -> show checked.
                            // Problem: selectedListIds is initially empty in state.
                            // We need to populate it with existing lists containing the book.
                            // We can't do setState in build.

                            // Alternative: The row checks if (selectedListIds contains id OR (list.bookIds contains bookId AND !unselectedListIds contains id))
                            // This is getting complex.

                            // Let's change the strategy for this sheet.
                            // Instead of extensive local state management, let's just use the list data.
                            // And maybe make the row tap interactive immediately? No, "Apply" button suggests batch.

                            // Let's assume for this step we will just toggle immediately? No, better UX is batch.

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () async {
                                  try {
                                    if (hasBook) {
                                      await ListService().removeBookFromList(
                                        list.id,
                                        widget.book.id,
                                      );
                                    } else {
                                      await ListService().addBookToList(
                                        list.id,
                                        widget.book.id,
                                      );
                                    }
                                  } catch (e) {
                                    // Handle error
                                  }
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? (hasBook
                                              ? context.primaryColor.withValues(
                                                  alpha: 0.05,
                                                )
                                              : Colors.white.withValues(
                                                  alpha: 0.02,
                                                ))
                                        : (hasBook
                                              ? context.primaryColor.withValues(
                                                  alpha: 0.05,
                                                )
                                              : Colors.transparent),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: hasBook
                                          ? context.primaryColor
                                          : (isDark
                                                ? Colors.white10
                                                : Colors.black.withValues(
                                                    alpha: 0.1,
                                                  )),
                                      width: hasBook ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color: hasBook
                                              ? context.primaryColor
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: hasBook
                                                ? context.primaryColor
                                                : (isDark
                                                      ? Colors.white24
                                                      : Colors.black26),
                                            width: 2,
                                          ),
                                        ),
                                        child: hasBook
                                            ? const Icon(
                                                PhosphorIconsBold.check,
                                                size: 16,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              list.name,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? Colors.white
                                                    : AppColors
                                                          .textLightPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Text(
                                                  '${list.bookCount} Ürün',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isDark
                                                        ? AppColors
                                                              .textDarkSecondary
                                                        : AppColors
                                                              .textLightSecondary,
                                                  ),
                                                ),
                                                if (list.isPublic) ...[
                                                  const SizedBox(width: 8),
                                                  Icon(
                                                    PhosphorIconsRegular.globe,
                                                    size: 12,
                                                    color: isDark
                                                        ? Colors.white38
                                                        : Colors.black38,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Herkese Açık',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isDark
                                                          ? Colors.white38
                                                          : Colors.black38,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      16,
                      24,
                      MediaQuery.of(context).padding.bottom + 16,
                    ),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      border: Border(
                        top: BorderSide(
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                      ),
                    ),
                    child: NeonGradientButton(
                      text: 'Tamam',
                      onPressed: () => Navigator.pop(context),
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

  // Desktop Layout - 3 Column Grid
  Widget _buildDesktopLayout(BuildContext context, bool isDark) {
    final book = widget.book;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: _isDirty
          ? FloatingActionButton(
              onPressed: _saveChanges,
              backgroundColor: context.primaryColor,
              foregroundColor: const Color(0xFF1D3D47),
              elevation: 4,
              child: const Icon(PhosphorIconsBold.check, size: 28),
            )
          : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column - Book Cover
          Container(
            width: 280,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Back Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      if (widget.onBack != null) {
                        widget.onBack!();
                      } else {
                        Navigator.pop(context);
                      }
                    },
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
                          PhosphorIconsRegular.arrowLeft,
                          size: 20,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Book Cover
                Container(
                  width: 220,
                  height: 330,
                  decoration: BoxDecoration(
                    color: context.subtleTint,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.primaryBorder, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: book.coverUrl != null
                        ? AppImage(
                            imageUrl: book.coverUrl,
                            fit: BoxFit.cover,
                            highQuality: true,
                            placeholder: Container(
                              color: isDark
                                  ? context.surfaceColor
                                  : Colors.grey[300],
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: context.primaryColor,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: Container(
                              color: isDark
                                  ? context.surfaceColor
                                  : Colors.grey[300],
                              child: Center(
                                child: Icon(
                                  PhosphorIconsRegular.imageBroken,
                                  size: 48,
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.black12,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: isDark
                                ? context.surfaceColor
                                : Colors.grey[300],
                            child: Center(
                              child: Icon(
                                PhosphorIconsRegular.book,
                                size: 48,
                                color: isDark ? Colors.white24 : Colors.black12,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          // Middle Column - Content Grid
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Header Card + Markets Card
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _buildHeaderCard(isDark)),
                        const SizedBox(width: 16),
                        Expanded(child: BookMarketsCard(book: widget.book)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Row 2: Info Card + Notes Card
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _buildInfoCardSection(isDark)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildNotesCard(isDark)),
                      ],
                    ),
                  ),

                ],
              ),
            ),
          ),

          // Right Column - Action Buttons
          Container(
            width: 70,
            padding: const EdgeInsets.only(top: 24, right: 16),
            child: Column(
              children: [
                // Share Button
                _buildCoverActionButton(
                  context,
                  icon: PhosphorIconsRegular.shareNetwork,
                  onTap: () {
                    String? url = widget.book.previewLink;
                    if (url == null && widget.book.isbn != null) {
                      url =
                          'https://books.google.com/books?vid=ISBN${widget.book.isbn}';
                    }
                    final text =
                        "Bu kitaba bir göz at: ${widget.book.title} - ${widget.book.author}\n${url ?? ''}";
                    Share.share(text, subject: widget.book.title);
                  },
                  isDark: isDark,
                ),

                // Edit Button - Only show for library owner
                if (_isOwner) ...[
                  const SizedBox(height: 12),
                  _buildCoverActionButton(
                    context,
                    icon: PhosphorIconsRegular.pencilSimple,
                    onTap: () async {
                      if (widget.onEdit != null) {
                        widget.onEdit!(widget.book);
                      } else {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddBookScreen(bookToEdit: widget.book),
                          ),
                        );
                        if (result == true && mounted) {
                          if (widget.onBack != null) {
                            widget.onBack!();
                          }
                        }
                      }
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildCoverActionButton(
                    context,
                    icon: PhosphorIconsRegular.trash,
                    onTap: () => _showDeleteDialog(context),
                    isDark: isDark,
                  ),
                ],
                const SizedBox(height: 12),

                // Heart Button
                _buildHeartButton(isDark),
                const SizedBox(height: 12),

                // Add to List Button
                _buildCoverActionButton(
                  context,
                  icon: PhosphorIconsRegular.listBullets,
                  onTap: () => _showAddToListSheet(),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Header Card for Desktop - Title, Author, Rating, Status
  Widget _buildHeaderCard(bool isDark) {
    final book = widget.book;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? context.surfaceColor.withValues(alpha: 0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.primaryBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            book.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textLightPrimary,
            ),
          ),
          const SizedBox(height: 4),
          // Author
          Text(
            book.author,
            style: TextStyle(
              fontSize: 15,
              color: isDark
                  ? AppColors.textDarkSecondary
                  : AppColors.textLightSecondary,
            ),
          ),
          const SizedBox(height: 16),
          // Rating
          _buildRatingSection(isDark),

        ],
      ),
    );
  }
}
