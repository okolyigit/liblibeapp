import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/theme.dart';
import '../widgets/app_image.dart';
import '../models/shopping_item.dart';
import '../models/library.dart';
import '../services/shopping_service.dart';
import '../services/library_service.dart';
import '../widgets/app_notification.dart';
import '../widgets/app_back_button.dart';
import '../widgets/neon_gradient_button.dart';
import 'package:url_launcher/url_launcher.dart';

class ShoppingItemDetailScreen extends StatefulWidget {
  final ShoppingItem item;
  final VoidCallback? onBack;
  final VoidCallback? onPurchased;

  const ShoppingItemDetailScreen({
    super.key,
    required this.item,
    this.onBack,
    this.onPurchased,
  });

  @override
  State<ShoppingItemDetailScreen> createState() =>
      _ShoppingItemDetailScreenState();
}

class _ShoppingItemDetailScreenState extends State<ShoppingItemDetailScreen> {

  void _showPurchaseSheet() {
    final isDark = context.isDark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PurchaseBottomSheet(
        item: widget.item,
        isDark: isDark,
        onPurchased: () {
          Navigator.pop(context); // Close bottom sheet
          if (widget.onPurchased != null) {
            widget.onPurchased!();
          } else if (widget.onBack != null) {
            widget.onBack!();
          } else {
            Navigator.pop(context); // Pop detail screen
          }
        },
      ),
    );
  }

  Future<void> _deleteItem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kitabı Sil'),
        content: const Text(
          'Bu kitabı alışveriş listesinden silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Sil',
              style: TextStyle(color: Colors.red[400]),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ShoppingService().deleteItem(widget.item.id);
        if (mounted) {
          AppNotification.success(context, 'Kitap listeden silindi');
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final item = widget.item;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Desktop layout for wide screens
        if (constraints.maxWidth > 900) {
          return _buildDesktopLayout(context, isDark);
        }

        // Mobile layout
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            slivers: [
              // App Bar with Cover
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                backgroundColor: isDark
                    ? context.themeBackground
                    : AppColors.bgLightPrimary,
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
                actions: const [],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: context.themeBackground),
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
                              child: item.coverUrl != null
                                  ? AppImage(
                                      imageUrl: item.coverUrl,
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
                      // Shopping badge overlay
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                PhosphorIconsBold.shoppingCart,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Satın Alınacak',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Action Buttons Column (Right aligned)
                      Positioned(
                        right: 16,
                        bottom: 80, // Above the overlay badge
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildCoverActionButton(
                              context,
                              icon: PhosphorIconsRegular.trash,
                              onTap: _deleteItem,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Primary color divider
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
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Author
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Column(
                            children: [
                              Text(
                                item.title,
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
                                item.author,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark
                                      ? AppColors.textDarkSecondary
                                      : AppColors.textLightSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // "Satın Aldım" Button — Primary CTA
                      _buildPurchaseButton(isDark),

                      const SizedBox(height: 32),

                      // Description
                      if (item.description != null &&
                          item.description!.isNotEmpty) ...[
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
                          item.description!,
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

                      // Info Card
                      _buildInfoCard(isDark),
                      const SizedBox(height: 16),

                      // Purchase Link Card
                      if ((item.purchaseLink != null &&
                              item.purchaseLink!.isNotEmpty) ||
                          (item.isbn != null && item.isbn!.isNotEmpty)) ...[
                        _buildPurchaseLinkCard(isDark),
                        const SizedBox(height: 16),
                      ],

                      const SizedBox(height: 24),


                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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

  Widget _buildDesktopLayout(BuildContext context, bool isDark) {
    final item = widget.item;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                Row(
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
                    const SizedBox(width: 12),
                    Text(
                      'Alışveriş Listesine Dön',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white70 : AppColors.textLightPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 250,
                            height: 375,
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
                              child: item.coverUrl != null
                                  ? AppImage(
                                      imageUrl: item.coverUrl,
                                      fit: BoxFit.cover,
                                      highQuality: true,
                                      errorWidget: Center(
                                        child: Icon(
                                          PhosphorIconsRegular.imageBroken,
                                          size: 48,
                                          color: isDark
                                              ? Colors.white24
                                              : Colors.black12,
                                        ),
                                      ),
                                    )
                                  : Center(
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
                          const SizedBox(width: 16),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildCoverActionButton(
                                context,
                                icon: PhosphorIconsRegular.trash,
                                onTap: _deleteItem,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ],
                      ),
                    const SizedBox(width: 32),

                    // Info column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Shopping badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  PhosphorIconsRegular.shoppingCart,
                                  color: Colors.orange[700],
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Alışveriş Listesinde',
                                  style: TextStyle(
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textLightPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.author,
                            style: TextStyle(
                              fontSize: 18,
                              color: isDark
                                  ? AppColors.textDarkSecondary
                                  : AppColors.textLightSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Purchase Button
                          _buildPurchaseButton(isDark),

                          const SizedBox(height: 24),

                          // Info card
                          _buildInfoCard(isDark),

                          if ((item.purchaseLink != null &&
                                  item.purchaseLink!.isNotEmpty) ||
                              (item.isbn != null && item.isbn!.isNotEmpty)) ...[
                            const SizedBox(height: 16),
                            _buildPurchaseLinkCard(isDark),
                          ],

                          if (item.description != null &&
                              item.description!.isNotEmpty) ...[
                            const SizedBox(height: 24),
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
                              item.description!,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: isDark
                                    ? AppColors.textDarkSecondary
                                    : AppColors.textLightSecondary,
                              ),
                            ),
                          ],

                          const SizedBox(height: 32),

                          // Delete
                          TextButton.icon(
                            onPressed: _deleteItem,
                            icon: Icon(
                              PhosphorIconsRegular.trash,
                              color: Colors.red[400],
                            ),
                            label: Text(
                              'Listeden Kaldır',
                              style: TextStyle(color: Colors.red[400]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPurchaseButton(bool isDark) {
    return NeonGradientButton(
      onPressed: _showPurchaseSheet,
      text: 'Satın Aldım',
    );
  }

  Widget _buildInfoCard(bool isDark) {
    final item = widget.item;
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
          Text(
            "Kitap Bilgileri",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textLightPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow("Tür", item.genre, PhosphorIconsRegular.tag, isDark),
          if (item.publisher != null && item.publisher!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              "Yayınevi",
              item.publisher!,
              PhosphorIconsRegular.buildings,
              isDark,
            ),
          ],
          if (item.publishedDate != null &&
              item.publishedDate!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              "Yayın Tarihi",
              item.publishedDate!,
              PhosphorIconsRegular.calendarBlank,
              isDark,
            ),
          ],
          if (item.pageCount != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              "Sayfa Sayısı",
              item.pageCount.toString(),
              PhosphorIconsRegular.bookOpen,
              isDark,
            ),
          ],
          if (item.isbn != null && item.isbn!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              "ISBN",
              item.isbn!,
              PhosphorIconsRegular.barcode,
              isDark,
            ),
          ],
          if (item.language != null && item.language!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              "Dil",
              item.language!,
              PhosphorIconsRegular.translate,
              isDark,
            ),
          ],
          if (item.categories.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: item.categories.map((cat) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: context.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPurchaseLinkCard(bool isDark) {
    final item = widget.item;
    final hasIsbn = item.isbn != null && item.isbn!.isNotEmpty;
    final hasLink = item.purchaseLink != null && item.purchaseLink!.isNotEmpty;

    if (!hasIsbn && !hasLink) return const SizedBox.shrink();

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
          Text(
            "Satın Alma Seçenekleri",
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
                _buildMarketIconBtn(
                  "assets/icon/amazon.png",
                  "https://www.amazon.com.tr/s?k=${item.isbn}",
                  Colors.white,
                ),
                _buildMarketIconBtn(
                  "assets/icon/hepsiburada.png",
                  "https://www.hepsiburada.com/ara?q=${item.isbn}",
                  Colors.white,
                ),
                _buildMarketIconBtn(
                  "assets/icon/trendyol.png",
                  "https://www.trendyol.com/sr?q=${item.isbn}",
                  const Color(0xFFF27A1A),
                ),
              ],
            )
          else if (hasLink)
            SizedBox(
              width: double.infinity,
              child: NeonGradientButton(
                text: "Satın Al",
                onPressed: () async {
                  if (item.purchaseLink != null) {
                    unawaited(
                      launchUrl(
                        Uri.parse(item.purchaseLink!),
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

  Widget _buildMarketIconBtn(String assetPath, String url, Color bgColor) {
    final isDark = context.isDark;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            ),
            borderRadius: BorderRadius.circular(11),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(
                child: Image.asset(
                  assetPath,
                  height: 32,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(PhosphorIconsRegular.warning, size: 24),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon,
    bool isDark,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.primaryColor),
        const SizedBox(width: 12),
        Text(
          "$label: ",
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? AppColors.textDarkSecondary
                : AppColors.textLightSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textLightPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// ======================================
// Purchase Bottom Sheet (Library Picker)
// ======================================

class _PurchaseBottomSheet extends StatefulWidget {
  final ShoppingItem item;
  final bool isDark;
  final VoidCallback onPurchased;

  const _PurchaseBottomSheet({
    required this.item,
    required this.isDark,
    required this.onPurchased,
  });

  @override
  State<_PurchaseBottomSheet> createState() => _PurchaseBottomSheetState();
}

class _PurchaseBottomSheetState extends State<_PurchaseBottomSheet> {
  bool _isMoving = false;
  String? _selectedLibraryId;

  Future<void> _moveToLibrary() async {
    if (_selectedLibraryId == null) {
      AppNotification.warning(context, 'Lütfen bir kütüphane seçin');
      return;
    }

    setState(() => _isMoving = true);

    try {
      await ShoppingService().moveToLibrary(
        widget.item.id,
        _selectedLibraryId!,
      );
      if (mounted) {
        AppNotification.success(
          context,
          '${widget.item.title} kütüphanenize eklendi!',
        );
        widget.onPurchased();
      }
    } catch (e) {
      if (mounted) {
        AppNotification.error(context, 'Hata: $e');
        setState(() => _isMoving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: widget.isDark
            ? context.surfaceColor
            : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: context.primaryColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: widget.isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        PhosphorIconsBold.shoppingCart,
                        color: Colors.orange[700],
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Satın Aldım!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: widget.isDark
                                  ? Colors.white
                                  : AppColors.textLightPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Kitabı hangi kütüphaneye eklemek istiyorsunuz?',
                            style: TextStyle(
                              fontSize: 13,
                              color: widget.isDark
                                  ? AppColors.textDarkSecondary
                                  : AppColors.textLightSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Library List
          Flexible(
            child: StreamBuilder<List<Library>>(
              stream: LibraryService().getUserLibraries(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final libraries = snapshot.data ?? [];
                if (libraries.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Henüz kütüphaneniz yok.',
                      style: TextStyle(
                        color: widget.isDark
                            ? Colors.white54
                            : AppColors.textLightSecondary,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: libraries.length,
                  itemBuilder: (context, index) {
                    final library = libraries[index];
                    final isSelected = _selectedLibraryId == library.id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedLibraryId = library.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? context.primaryColor.withValues(alpha: 0.1)
                                : context.surfaceColor.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? context.primaryColor
                                  : (widget.isDark
                                      ? Colors.white10
                                      : Colors.black12),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? context.primaryColor
                                      : context.primaryColor
                                            .withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  PhosphorIconsRegular.books,
                                  size: 18,
                                  color: isSelected
                                      ? Colors.white
                                      : context.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      library.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: widget.isDark
                                            ? Colors.white
                                            : AppColors.textLightPrimary,
                                      ),
                                    ),
                                    if (library.description != null &&
                                        library.description!.isNotEmpty)
                                      Text(
                                        library.description!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: widget.isDark
                                              ? AppColors.textDarkSecondary
                                              : AppColors.textLightSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  PhosphorIconsBold.checkCircle,
                                  color: context.primaryColor,
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

          // Confirm button
          Padding(
            padding: const EdgeInsets.all(16),
            child: NeonGradientButton(
              onPressed: _isMoving ? () {} : _moveToLibrary,
              text: 'Kütüphaneye Ekle',
              isLoading: _isMoving,
            ),
          ),
        ],
      ),
    );
  }
}
