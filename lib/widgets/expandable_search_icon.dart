import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/theme.dart';
import '../models/book.dart';
import '../models/reading_list.dart';
import '../services/book_service.dart';
import '../services/list_service.dart';
import '../screens/book_detail.dart';
import '../screens/list_detail.dart';
import '../screens/barcode_scanner_screen.dart';
import 'app_image.dart';

/// A search icon that expands into a full-width search bar when tapped.
/// Designed for mobile headers - shows as an icon, expands to cover the entire header.
class ExpandableSearchIcon extends StatefulWidget {
  final String hintText;
  final double? maxWidth;

  const ExpandableSearchIcon({
    super.key,
    this.hintText = "Kitap, Yazar, Liste Ara...",
    this.maxWidth,
  });

  @override
  State<ExpandableSearchIcon> createState() => _ExpandableSearchIconState();
}

class _ExpandableSearchIconState extends State<ExpandableSearchIcon>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _searchOverlay;
  OverlayEntry? _resultsOverlay;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _searchController.dispose();
    _hideAllOverlays();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _isExpanded) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!_focusNode.hasFocus && mounted) {
          _closeSearch();
        }
      });
    }
  }

  void _openSearch() {
    setState(() => _isExpanded = true);
    _showSearchOverlay();
    _animationController.forward();
  }

  void _closeSearch() {
    _hideAllOverlays();
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isExpanded = false;
          _searchController.clear();
        });
      }
    });
  }

  void _hideAllOverlays() {
    _searchOverlay?.remove();
    _searchOverlay = null;
    _resultsOverlay?.remove();
    _resultsOverlay = null;
  }

  void _showSearchOverlay() {
    _hideAllOverlays();

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset iconPosition = renderBox.localToGlobal(Offset.zero);
    final Size iconSize = renderBox.size;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = context.isDark;

    // Determine target width and position
    // We assume the header usually has ~12px padding on the right.
    // We align the expanded search bar so its right edge matches the container's right edge.
    // Container Right Edge ~ Icon Right Edge + 12 approx?
    // Let's use the icon as the anchor.
    // Expanded Bar Right Edge = iconPosition.dx + iconSize.width + 12 (approx padding compensation)

    // Safer approach:
    // If maxWidth is set, we use it.
    // Layout Left = (Icon Right + 12) - MaxWidth.
    // We clamp Left to be at least 0.

    final double targetWidth = widget.maxWidth ?? screenWidth;

    // Calculate Left position to make the bar end at the right side
    // We assume standard 12px padding exists in parent.
    double layoutRightEdge = iconPosition.dx + iconSize.width + 12;
    if (widget.maxWidth == null) {
      layoutRightEdge = screenWidth; // Fallback to full screen logic
    }

    double layoutLeft = layoutRightEdge - targetWidth;
    // ensure within screen bounds
    if (layoutLeft < 0) layoutLeft = 0;

    // Recalculate width based on clamped left
    final double effectiveWidth = layoutRightEdge - layoutLeft;

    // Calculate header area (12px padding on both sides internally for the bar)
    const horizontalPadding = 12.0;
    final searchBarWidth = effectiveWidth - (horizontalPadding * 2);

    _searchOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Tap-to-close backdrop
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeSearch,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Opaque background to cover header elements
          Positioned(
            top: iconPosition.dy - 8,
            left: layoutLeft,
            width: effectiveWidth,
            height: 56,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                color: isDark
                    ? context.themeBackground
                    : AppColors.bgLightPrimary,
              ),
            ),
          ),
          // Search bar positioned at header level
          Positioned(
            top: iconPosition.dy,
            left: layoutLeft + horizontalPadding,
            width: searchBarWidth,
            height: 40,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildExpandedSearchBar(isDark, searchBarWidth),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_searchOverlay!);

    // Request focus after overlay is inserted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _showResultsOverlay(double searchBarWidth) {
    _resultsOverlay?.remove();
    _resultsOverlay = null;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset position = renderBox.localToGlobal(Offset.zero);
    const horizontalPadding = 12.0;

    _resultsOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: position.dy + 48, // Below search bar
        left: horizontalPadding,
        width: searchBarWidth,
        child: _buildResultsDropdown(),
      ),
    );

    Overlay.of(context).insert(_resultsOverlay!);
  }

  Widget _buildExpandedSearchBar(bool isDark, double width) {
    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? context.surfaceColor.withValues(alpha: 0.95)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.primaryColor.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(
                  PhosphorIconsRegular.magnifyingGlass,
                  size: 18,
                  color: context.primaryColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : AppColors.textLightPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty) {
                        _showResultsOverlay(width);
                      } else {
                        _resultsOverlay?.remove();
                        _resultsOverlay = null;
                      }
                      _resultsOverlay?.markNeedsBuild();
                    },
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BarcodeScannerScreen(),
                      ),
                    );
                    if (result != null && result is String) {
                      _searchController.text = result;
                      _showResultsOverlay(width);
                      _resultsOverlay?.markNeedsBuild();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      PhosphorIconsRegular.barcode,
                      size: 20,
                      color: context.primaryColor,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _closeSearch,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
                    child: Icon(
                      PhosphorIconsRegular.x,
                      size: 18,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsDropdown() {
    return ListenableBuilder(
      listenable: _searchController,
      builder: (context, child) {
        final query = _searchController.text;
        if (query.isEmpty) return const SizedBox.shrink();

        final isDark = context.isDark;

        return FutureBuilder(
          future: Future.wait([
            BookService().searchBooks(query),
            ListService().searchLists(query),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildDropdownContainer(
                isDark,
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              );
            }

            final results = snapshot.data as List<dynamic>?;
            final filteredBooks =
                (results?[0] as List<Book>?)?.take(4).toList() ?? [];
            final filteredLists =
                (results?[1] as List<ReadingList>?)?.take(3).toList() ?? [];

            if (filteredBooks.isEmpty && filteredLists.isEmpty) {
              return _buildDropdownContainer(
                isDark,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Sonuç bulunamadı",
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black45,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }

            return _buildDropdownContainer(
              isDark,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (filteredBooks.isNotEmpty) ...[
                    _buildSectionHeader(context, "KİTAPLAR"),
                    ...filteredBooks.map(
                      (book) => _buildBookResultItem(
                        context,
                        book: book,
                        onTap: () {
                          _closeSearch();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  BookDetailScreen(book: book),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  if (filteredLists.isNotEmpty) ...[
                    _buildSectionHeader(context, "LİSTELER"),
                    ...filteredLists.map((list) {
                      // Check if it's favorites by id or name
                      final isFavorites =
                          list.id == 'favorites' ||
                          list.name.toLowerCase().contains('beğenilen') ||
                          list.name.toLowerCase().contains('favoriler');
                      return _buildResultItem(
                        context,
                        icon: isFavorites
                            ? PhosphorIconsFill.heart
                            : PhosphorIconsRegular.listDashes,
                        title: list.name,
                        subtitle: "${list.bookCount} Kitap",
                        onTap: () {
                          _closeSearch();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ListDetailScreen(list: list),
                            ),
                          );
                        },
                        iconColor: isFavorites
                            ? Colors.red
                            : context.primaryColor,
                      );
                    }),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDropdownContainer(bool isDark, {required Widget child}) {
    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? context.surfaceColor.withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.98),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildBookResultItem(
    BuildContext context, {
    required Book book,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDark;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Book cover or fallback icon
            Container(
              width: 32,
              height: 44,
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                    ? AppImage(
                        imageUrl: book.coverUrl!,
                        width: 32,
                        height: 44,
                        fit: BoxFit.cover,
                        errorWidget: Center(
                          child: Icon(
                            PhosphorIconsFill.bookOpen,
                            size: 16,
                            color: context.primaryColor,
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          PhosphorIconsFill.bookOpen,
                          size: 16,
                          color: context.primaryColor,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textLightPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.author,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.white38
                          : AppColors.textLightSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final effectiveIconColor = iconColor ?? context.primaryColor;
    final isDark = context.isDark;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: effectiveIconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textLightPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.white38
                          : AppColors.textLightSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return GestureDetector(
      onTap: _openSearch,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.subtleTint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Center(
          child: Icon(
            PhosphorIconsRegular.magnifyingGlass,
            size: 20,
            color: isDark
                ? Colors.white.withValues(alpha: 0.6)
                : Colors.black54,
          ),
        ),
      ),
    );
  }
}
