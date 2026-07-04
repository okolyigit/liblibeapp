import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'app_image.dart';

import '../theme/theme.dart';
import '../models/book.dart';
import '../screens/book_detail.dart';

/// A standardized book card widget used throughout the app.
///
/// Goal: The cover image must keep a stable aspect ratio on every screen size.
/// Fix: Render cover with [AspectRatio] (default 2/3) instead of Expanded.
class StandardBookCard extends StatelessWidget {
  final Book book;

  /// In Grid usage, keep these null so the Grid cell determines sizing.
  final double? width;
  final double? height;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const StandardBookCard({
    super.key,
    required this.book,
    this.width,
    this.height,
    this.onTap,
    this.onLongPress,
  });

  /// Typical book cover ratio (width/height).
  static const double coverAspectRatio = 2 / 3;

  /// Fixed meta area height (title + author).
  static const double metaHeight = 48;

  static const double _radius = 16;
  static const double _innerRadius = 14;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return GestureDetector(
      onTap:
          onTap ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookDetailScreen(book: book),
              ),
            );
          },
      onLongPress: onLongPress,
      child: SizedBox(
        width: width,
        height: height,
        child: Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(
              color: context.primaryColor.withValues(
                alpha: isDark ? 0.25 : 0.2,
              ),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cover (stable ratio)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(_innerRadius),
                  topRight: Radius.circular(_innerRadius),
                ),
                child: AspectRatio(
                  aspectRatio: coverAspectRatio,
                  child: Container(
                    width: double.infinity,
                    color: context.surfaceColor,
                    child: book.coverUrl != null
                        ? AppImage(
                            imageUrl: book.coverUrl,
                            fit: BoxFit.cover,
                            highQuality: true,
                          )
                        : _buildPlaceholder(isDark, context.surfaceColor),
                  ),
                ),
              ),

              // Title + Author (fixed height => stable total card height)
              SizedBox(
                height: metaHeight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: isDark
                              ? Colors.white
                              : AppColors.textLightPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        book.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textLightSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark, Color bgColor) {
    return Container(
      color: bgColor,
      child: Center(
        child: Icon(
          PhosphorIconsRegular.book,
          size: 40,
          color: isDark ? Colors.white24 : Colors.black12,
        ),
      ),
    );
  }

}
