import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../theme/theme.dart';
import '../widgets/error_state_view.dart';
import '../widgets/app_notification.dart';
import '../models/reading_list.dart';
import '../models/shopping_item.dart';
import '../services/list_service.dart';
import '../services/shopping_service.dart';
import 'list_detail.dart';
import 'shopping_list_screen.dart';
import '../widgets/expandable_search_icon.dart';
import '../widgets/neon_gradient_button.dart';
import '../widgets/app_header.dart';

class ListsScreen extends StatefulWidget {
  final bool showHeader;
  final Function(ReadingList)? onListSelected;
  final VoidCallback? onNavigateToShopping;

  const ListsScreen({
    super.key,
    this.showHeader = true,
    this.onListSelected,
    this.onNavigateToShopping,
  });

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    const headerHeight = 68.0;
    final statusBarTop = AppHeader.statusBarHeight(context);
    final topPadding =
        widget.showHeader ? headerHeight + statusBarTop + 8 : 24.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Scrollable content
          Positioned.fill(
            child: SafeArea(
              top: false,
              child: StreamBuilder<List<ReadingList>>(
                stream: ListService().getUserLists(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return ErrorStateView(
                      message: 'Listeler yüklenemedi',
                      detail: '${snapshot.error}',
                      onRetry: () => setState(() {}),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final lists = snapshot.data!;

                  // Sort lists: default lists first, then others
                  final defaultLists = lists.where((l) => l.isDefault).toList();
                  final userLists = lists.where((l) => !l.isDefault).toList();

                  return ListView(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(12, topPadding, 12, 120),
                    children: [
                      // Default lists (Favorites)
                      ...defaultLists.map(
                        (list) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildListCard(list),
                        ),
                      ),

                      // Shopping List card (fixed, non-deletable)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildShoppingListCard(isDark),
                      ),

                      // Separator between fixed lists and user lists
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.black12,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  'Listelerim',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black38,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.black12,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Empty state for user lists if none exist
                      if (userLists.isEmpty)
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.35,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: context.primaryColor.withValues(
                                      alpha: 0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    PhosphorIconsRegular.listPlus,
                                    size: 48,
                                    color: context.primaryColor.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Kendi listenizi oluşturun',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textLightPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Kitaplarınızı organize etmek için\nbir okuma listesi oluşturun',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.white54
                                        : AppColors.textLightSecondary,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  '+ butonunu kullanın',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white38
                                        : AppColors.textLightSecondary
                                              .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // User-created lists
                      ...userLists.map(
                        (list) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildListCard(list),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          // Fixed glass header
          if (widget.showHeader)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppHeader(
                scrollController: _scrollController,
                title: "Listelerim",
                titleSize: 24,
                actions: [
                  if (MediaQuery.of(context).size.width <= 670)
                    const ExpandableSearchIcon(hintText: 'Liste ara...'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Build the fixed shopping list card
  Widget _buildShoppingListCard(bool isDark) {
    return GestureDetector(
      onTap: () {
        if (widget.onNavigateToShopping != null) {
          widget.onNavigateToShopping!();
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ShoppingListScreen(),
            ),
          );
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? context.surfaceColor.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.orange.withValues(alpha: 0.5)
                    : Colors.orange.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Shopping cart icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    PhosphorIconsFill.shoppingCart,
                    color: Colors.orange[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alışveriş Listem',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : AppColors.textLightPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Satın almak istediğim kitaplar',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textLightSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Item count badge
                StreamBuilder<List<ShoppingItem>>(
                  stream: ShoppingService().getItems(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.length ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$count kitap',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textLightSecondary,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Get icon from string name
  IconData _getListIcon(String? iconName) {
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
      default:
        return PhosphorIconsRegular.listBullets;
    }
  }

  /// Get color from hex string
  Color _getListColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) {
      return context.primaryColor;
    }
    try {
      // Remove # if present and parse hex
      final hex = colorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return context.primaryColor;
    }
  }

  Widget _buildListCard(ReadingList list) {
    final isDark = context.isDark;

    return Slidable(
      key: Key(list.id),
      // Left side - Edit action (only for non-default lists)
      startActionPane: list.isDefault
          ? null
          : ActionPane(
              motion: const BehindMotion(),
              extentRatio: 0.25,
              children: [
                CustomSlidableAction(
                  onPressed: (context) => _showEditListDialog(list),
                  backgroundColor: context.primaryColor,
                  foregroundColor: const Color(0xFF1D3D47),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(PhosphorIconsRegular.pencilSimple),
                      SizedBox(height: 4),
                      Text(
                        'Düzenle',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      // Right side - Delete action (only for non-default lists)
      endActionPane: list.isDefault
          ? null
          : ActionPane(
              motion: const BehindMotion(),
              extentRatio: 0.25,
              children: [
                CustomSlidableAction(
                  onPressed: (context) => _deleteListWithUndo(list),
                  backgroundColor: Colors.red[400]!,
                  foregroundColor: const Color(0xFF1D3D47),
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(16),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(PhosphorIconsRegular.trash),
                      SizedBox(height: 4),
                      Text(
                        'Sil',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      child: GestureDetector(
        onTap: () {
          if (widget.onListSelected != null) {
            widget.onListSelected!(list);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ListDetailScreen(list: list),
              ),
            );
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? context.surfaceColor.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: list.isDefault
                      ? (isDark
                            ? Colors.red.withValues(alpha: 0.5)
                            : Colors.red.withValues(alpha: 0.4))
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : context.primaryColor.withValues(alpha: 0.4)),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  // Dynamic Icon with custom color
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getListColor(list.color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getListIcon(list.icon),
                      color: _getListColor(list.color),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          list.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : AppColors.textLightPrimary,
                          ),
                        ),
                        if (list.description != null &&
                            list.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            list.description!,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textDarkSecondary
                                  : AppColors.textLightSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Book count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${list.bookCount} kitap",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textDarkSecondary
                            : AppColors.textLightSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Three dots menu (hidden for default lists)
                  if (!list.isDefault)
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        PhosphorIconsRegular.dotsThreeVertical,
                        color: isDark ? Colors.white54 : Colors.grey[500],
                        size: 20,
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
                          _showEditListDialog(list);
                        } else if (value == 'delete') {
                          _deleteListWithUndo(list);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIconsRegular.pencilSimple,
                                color: context.primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Düzenle',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textLightPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIconsRegular.trash,
                                color: Colors.red[400],
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Sil',
                                style: TextStyle(
                                  color: Colors.red[400],
                                  fontWeight: FontWeight.w500,
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
      ),
    );
  }

  // showCreateListBottomSheet is now handled via widgets/create_list_bottom_sheet.dart

  void _showEditListDialog(ReadingList list) {
    final isDark = context.isDark;
    final nameController = TextEditingController(text: list.name);
    final descController = TextEditingController(text: list.description ?? '');
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
                              child: Icon(
                                PhosphorIconsRegular.x,
                                size: 24,
                                color: isDark ? Colors.white70 : Colors.black54,
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
                            labelText: 'Açıklama (isteğe bağlı)',
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
                                isSecondary: true,
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: NeonGradientButton(
                                text: 'Kaydet',
                                onPressed: () async {
                                  try {
                                    await ListService().updateList(
                                      list.id,
                                      name: nameController.text,
                                      description: descController.text,
                                    );

                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      AppNotification.success(
                                        context,
                                        'Liste güncellendi',
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      AppNotification.error(
                                        context,
                                        'Hata: $e',
                                      );
                                    }
                                  }
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

  /// Delete list with undo option
  void _deleteListWithUndo(ReadingList list) {
    // Don't allow deleting default lists
    if (list.isDefault) {
      AppNotification.error(context, 'Varsayılan listeler silinemez');
      return;
    }

    // Store list data for potential restoration
    final listData = list.toMap();
    final listId = list.id;

    // Delete immediately from Firestore
    ListService()
        .deleteList(listId)
        .then((_) {
          if (!mounted) return;

          // Show undo notification with action button
          AppNotification.show(
            context,
            message: '"${list.name}" silindi',
            type: NotificationType.error,
            duration: const Duration(seconds: 5),
            actionLabel: 'Geri Al',
            action: () async {
              // Restore the list
              try {
                await FirebaseFirestore.instance
                    .collection('lists')
                    .doc(listId)
                    .set(listData);
                if (mounted) {
                  AppNotification.success(
                    context,
                    '"${list.name}" geri yüklendi',
                  );
                }
              } catch (e) {
                if (mounted) {
                  AppNotification.error(context, 'Geri yükleme başarısız');
                }
              }
            },
          );
        })
        .catchError((e) {
          if (mounted) {
            AppNotification.error(context, 'Silme hatası: $e');
          }
        });
  }
}
