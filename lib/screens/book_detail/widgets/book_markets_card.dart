import 'dart:async';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/book.dart';
import '../../../theme/theme.dart';
import '../../../widgets/neon_gradient_button.dart';

/// "Satın Al" (Buy) card for a book detail screen. Shows quick links to Turkish
/// marketplaces when an ISBN is available, or a single button to the book's
/// own purchase link otherwise. Renders nothing when neither is present.
///
/// Extracted from `book_detail.dart` — purely presentational, driven only by
/// [book] data, so it carries no screen state.
class BookMarketsCard extends StatelessWidget {
  final Book book;
  const BookMarketsCard({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final hasIsbn = book.isbn != null && book.isbn!.isNotEmpty;
    final hasLink = book.purchaseLink != null && book.purchaseLink!.isNotEmpty;

    if (!hasIsbn && !hasLink) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? context.surfaceColor.withValues(alpha: 0.3) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.primaryBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Satın Al",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textLightPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (hasIsbn)
            Row(
              children: [
                _MarketIconButton(
                  assetPath: "assets/icon/amazon.png",
                  url: "https://www.amazon.com.tr/s?k=${book.isbn}",
                ),
                _MarketIconButton(
                  assetPath: "assets/icon/hepsiburada.png",
                  url: "https://www.hepsiburada.com/ara?q=${book.isbn}",
                ),
                _MarketIconButton(
                  assetPath: "assets/icon/trendyol.png",
                  url: "https://www.trendyol.com/sr?q=${book.isbn}",
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: NeonGradientButton(
                text: "Satın Al",
                onPressed: () async {
                  if (book.purchaseLink != null) {
                    unawaited(
                      launchUrl(
                        Uri.parse(book.purchaseLink!),
                        mode: LaunchMode.externalApplication,
                      ),
                    );
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _MarketIconButton extends StatelessWidget {
  final String assetPath;
  final String url;
  const _MarketIconButton({required this.assetPath, required this.url});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            ),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                // Light surface in every theme — brand logos (Amazon black
                // text, Hepsiburada/Trendyol orange) need a high-contrast
                // backdrop to stay legible. Slightly off-white to soften
                // the pop against the parent dark/glass card.
                color: isDark ? Colors.white.withValues(alpha: 0.92) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.06),
                  width: 0.5,
                ),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Center(
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(PhosphorIconsRegular.warning, size: 20),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
