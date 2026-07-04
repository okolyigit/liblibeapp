import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/theme.dart';
import '../models/book.dart';
import 'standard_book_card.dart';

/// A horizontal book carousel with navigation arrows for web.
/// Features an invisible guide container with arrows positioned half inside/half outside.
class WebBookCarousel extends StatefulWidget {
  final List<Book> books;
  final double cardWidth;
  final Function(Book)? onBookSelected;

  const WebBookCarousel({
    super.key,
    required this.books,
    required this.cardWidth,
    this.onBookSelected,
  });

  @override
  State<WebBookCarousel> createState() => _WebBookCarouselState();
}

class _WebBookCarouselState extends State<WebBookCarousel> {
  final ScrollController _scrollController = ScrollController();
  bool _showLeftArrow = false;
  bool _showRightArrow = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Check initial state after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollState());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    _checkScrollState();
  }

  void _checkScrollState() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;

    final showLeft = currentScroll > 10;
    final showRight = currentScroll < maxScroll - 10 && maxScroll > 0;

    if (_showLeftArrow != showLeft || _showRightArrow != showRight) {
      setState(() {
        _showLeftArrow = showLeft;
        _showRightArrow = showRight;
      });
    }
  }

  void _scrollLeft() {
    final screenWidth = MediaQuery.of(context).size.width;
    _scrollController.animateTo(
      (_scrollController.offset - screenWidth * 0.5).clamp(
        0,
        _scrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollRight() {
    final screenWidth = MediaQuery.of(context).size.width;
    _scrollController.animateTo(
      (_scrollController.offset + screenWidth * 0.5).clamp(
        0,
        _scrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final coverHeight = widget.cardWidth / StandardBookCard.coverAspectRatio;
    final cardHeight = coverHeight + StandardBookCard.metaHeight + 6;

    // Arrow button size
    const arrowSize = 36.0;
    const arrowOffset = arrowSize / 2; // Half outside

    return SizedBox(
      height: cardHeight + 16,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Invisible guide container with content
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.all(8),
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: widget.books.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) => SizedBox(
                width: widget.cardWidth,
                child: StandardBookCard(
                  book: widget.books[index],
                  onTap: widget.onBookSelected != null
                      ? () => widget.onBookSelected!(widget.books[index])
                      : null,
                ),
              ),
            ),
          ),

          // Left arrow - half inside/half outside
          if (_showLeftArrow)
            Positioned(
              left: 8 - arrowOffset,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildArrowButton(
                  icon: PhosphorIconsRegular.caretLeft,
                  onTap: _scrollLeft,
                  isDark: isDark,
                  size: arrowSize,
                ),
              ),
            ),

          // Right arrow - half inside/half outside
          if (_showRightArrow)
            Positioned(
              right: 8 - arrowOffset,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildArrowButton(
                  icon: PhosphorIconsRegular.caretRight,
                  onTap: _scrollRight,
                  isDark: isDark,
                  size: arrowSize,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildArrowButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    required double size,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2A1A) : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: context.primaryColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDark ? Colors.white : context.primaryColor,
          ),
        ),
      ),
    );
  }
}
