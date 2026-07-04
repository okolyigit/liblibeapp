import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/theme.dart';
import '../widgets/app_image.dart';
import '../models/shopping_item.dart';
import '../services/shopping_service.dart';
import '../widgets/app_back_button.dart';
import 'shopping_item_detail.dart';
import 'add_shopping_item_screen.dart';
import '../widgets/neon_gradient_button.dart';
import '../widgets/app_header.dart';

class ShoppingListScreen extends StatefulWidget {
  final bool showHeader;
  final Function(ShoppingItem)? onItemSelected;
  final VoidCallback? onNavigateToAdd;

  const ShoppingListScreen({
    super.key,
    this.showHeader = true,
    this.onItemSelected,
    this.onNavigateToAdd,
  });

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  Stream<List<ShoppingItem>>? _itemsStream;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _itemsStream = ShoppingService().getItems();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    const headerHeight = 68.0;

    if (widget.showHeader) {
      final statusBarTop = AppHeader.statusBarHeight(context);
      return Scaffold(
        backgroundColor: widget.showHeader
            ? Theme.of(context).scaffoldBackgroundColor
            : Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(
              child: SafeArea(
                top: false,
                child: _buildContent(
                  context,
                  isDark,
                  topPadding: headerHeight + statusBarTop,
                ),
              ),
            ),
            // Fixed glass header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppHeader(
                  scrollController: _scrollController,
                  title: "Alışveriş Listem",
                  titleSize: 24,
                  leading: (Navigator.canPop(context) &&
                          MediaQuery.of(context).size.width <= 670)
                      ? AppBackButton(
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                        )
                      : null,
                  actions: [
                    IconButton(
                      icon: Icon(
                        PhosphorIconsRegular.plus,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      onPressed: () {
                        if (widget.onNavigateToAdd != null) {
                          widget.onNavigateToAdd!();
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const AddShoppingItemScreen(),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
        ),
      );
    }

    // Dashboard mode
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: _buildContent(context, isDark, topPadding: 0),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    bool isDark, {
    double topPadding = 0,
  }) {
    return StreamBuilder<List<ShoppingItem>>(
      stream: _itemsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return _buildEmptyState(context, isDark, topPadding);
        }

        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(16, topPadding + 16, 16, 120),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildItemCard(context, items[index], isDark),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, double topPadding) {
    return Padding(
      padding: EdgeInsets.fromLTRB(32, topPadding, 32, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIconsRegular.shoppingCart,
              size: 48,
              color: Colors.orange.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Alışveriş listeniz boş',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textLightPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kitapçıda satın almak istediğiniz\nkitapları buraya ekleyin',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : AppColors.textLightSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          NeonGradientButton(
            onPressed: () {
              if (widget.onNavigateToAdd != null) {
                widget.onNavigateToAdd!();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddShoppingItemScreen(),
                  ),
                );
              }
            },
            text: 'Kitap Ekle',
            width: 200,
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    ShoppingItem item,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        if (widget.onItemSelected != null) {
          widget.onItemSelected!(item);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ShoppingItemDetailScreen(item: item),
            ),
          );
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceColor.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: context.primaryColor.withValues(
                  alpha: isDark ? 0.2 : 0.25,
                ),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Cover
                Container(
                  width: 60,
                  height: 85,
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: item.coverUrl != null
                        ? AppImage(
                            imageUrl: item.coverUrl,
                            fit: BoxFit.cover,
                            errorWidget: Center(
                              child: Icon(
                                PhosphorIconsRegular.imageBroken,
                                size: 24,
                                color:
                                    isDark ? Colors.white24 : Colors.black12,
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
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : AppColors.textLightPrimary,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.author,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textLightSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Shopping badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIconsRegular.shoppingCart,
                              size: 12,
                              color: Colors.orange[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Satın Alınacak',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
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
}
