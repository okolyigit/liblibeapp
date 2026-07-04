import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/theme.dart';
import '../widgets/error_state_view.dart';
import '../widgets/app_notification.dart';
import '../models/library.dart';
import '../widgets/app_back_button.dart';
import '../services/library_service.dart';
import 'library_detail.dart';
import '../widgets/expandable_search_icon.dart';
import '../widgets/glass_dialog.dart';
import '../widgets/neon_gradient_button.dart';
import '../widgets/app_header.dart';

class LibrariesScreen extends StatefulWidget {
  final bool showHeader;
  final Function(Library)? onLibrarySelected;

  const LibrariesScreen({
    super.key,
    this.showHeader = true,
    this.onLibrarySelected,
  });

  @override
  State<LibrariesScreen> createState() => _LibrariesScreenState();
}

class _LibrariesScreenState extends State<LibrariesScreen> {
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
        widget.showHeader ? headerHeight + statusBarTop : 0.0;

    return Scaffold(
      backgroundColor: widget.showHeader
          ? Theme.of(context).scaffoldBackgroundColor
          : Colors.transparent,
      body: Stack(
        children: [
          // Scrollable content
          Positioned.fill(
            child: SafeArea(
              top: false,
              child: StreamBuilder<List<Library>>(
                stream: LibraryService().getUserLibraries(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return ErrorStateView(
                      message: 'Kütüphaneler yüklenemedi',
                      detail: '${snapshot.error}',
                      onRetry: () => setState(() {}),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final libraries = snapshot.data!;

                  if (libraries.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.only(top: topPadding),
                      child: Center(
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
                              'Henüz bir kütüphaneniz yok',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Separate owned and shared libraries
                  final currentUserId = LibraryService().currentUserId;
                  final ownedLibs = libraries
                      .where((l) => l.ownerId == currentUserId)
                      .toList();
                  final sharedLibs = libraries
                      .where((l) => l.ownerId != currentUserId)
                      .toList();

                  // Further separate default from user-created owned libraries
                  final defaultLib = ownedLibs
                      .where((l) => l.isDefault)
                      .toList();
                  final userOwnedLibs = ownedLibs
                      .where((l) => !l.isDefault)
                      .toList();

                  return ListView(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(
                      12,
                      widget.showHeader ? topPadding + 8 : 24,
                      12,
                      120,
                    ),
                    children: [
                      // Default Library (Kişisel Kütüphanem)
                      ...defaultLib.map(
                        (lib) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildLibraryCard(lib, isOwner: true),
                        ),
                      ),

                      // Divider for other owned libraries
                      if (defaultLib.isNotEmpty && userOwnedLibs.isNotEmpty)
                        _buildSectionDivider('Diğer Kütüphanelerim', isDark),

                      // User created owned libraries
                      ...userOwnedLibs.map(
                        (lib) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildLibraryCard(lib, isOwner: true),
                        ),
                      ),

                      // Shared libraries section
                      if (sharedLibs.isNotEmpty) ...[
                        _buildSectionDivider(
                          'Üyesi Olduğum Kütüphaneler',
                          isDark,
                        ),
                        ...sharedLibs.map(
                          (lib) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildLibraryCard(lib, isOwner: false),
                          ),
                        ),
                      ],
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
                  title: "Kütüphanelerim",
                  titleSize: 24,
                  leading: (Navigator.canPop(context) &&
                          MediaQuery.of(context).size.width <= 670)
                      ? AppBackButton(
                          onPressed: () => Navigator.pop(context),
                        )
                      : null,
                  actions: [
                    if (MediaQuery.of(context).size.width <= 670)
                      const ExpandableSearchIcon(
                        hintText: 'Kütüphane ara...',
                      ),
                    GestureDetector(
                      onTap: () => _showCreateLibraryDialog(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.subtleTint,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : Colors.black12,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            PhosphorIconsRegular.plus,
                            size: 20,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  /// Get icon from string name
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

  /// Get color from hex string
  Color _getColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) {
      return context.primaryColor;
    }
    try {
      final hex = colorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return context.primaryColor;
    }
  }

  /// Build section divider with label
  Widget _buildSectionDivider(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: isDark ? Colors.white12 : Colors.black12,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: isDark ? Colors.white12 : Colors.black12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryCard(Library library, {bool isOwner = true}) {
    final isDark = context.isDark;
    final canEdit = isOwner && !library.isDefault;

    return Slidable(
      key: Key(library.id),
      // Left side - Edit action (only for owned, non-default)
      startActionPane: !canEdit
          ? null
          : ActionPane(
              motion: const BehindMotion(),
              extentRatio: 0.25,
              children: [
                CustomSlidableAction(
                  onPressed: (context) => _showEditLibraryDialog(library),
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
      // Right side - Delete action (only for owned, non-default)
      endActionPane: !canEdit
          ? null
          : ActionPane(
              motion: const BehindMotion(),
              extentRatio: 0.25,
              children: [
                CustomSlidableAction(
                  onPressed: (context) => _deleteLibraryWithUndo(library),
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
          if (widget.onLibrarySelected != null) {
            widget.onLibrarySelected!(library);
          } else {
            // Navigate to Library Detail
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LibraryDetailScreen(library: library),
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
                    ? (Theme.of(context).cardTheme.color ??
                          context.surfaceColor)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : context.primaryColor.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getColor(library.color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIcon(library.icon),
                      color: _getColor(library.color),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Content - different display for shared libraries
                  Expanded(
                    child: isOwner
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                library.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textLightPrimary,
                                ),
                              ),
                              if (library.description != null &&
                                  library.description!.isNotEmpty) ...[
                                Text(
                                  library.description!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          )
                        : FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(library.ownerId)
                                .get(),
                            builder: (context, snapshot) {
                              final ownerName =
                                  snapshot.data?.get('displayName')
                                      as String? ??
                                  snapshot.data?.get('email') as String? ??
                                  'Bir kullanıcı';
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$ownerName tarafından paylaşılan',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.textDarkSecondary
                                          : AppColors.textLightSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    library.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.textLightPrimary,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),

                  // Options (only for owned, non-default libraries)
                  if (canEdit)
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        PhosphorIconsRegular.dotsThreeVertical,
                        color: isDark ? Colors.white54 : Colors.grey[500],
                        size: 20,
                      ),
                      color: context.surfaceColor,
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditLibraryDialog(library);
                        } else if (value == 'delete') {
                          _deleteLibraryWithUndo(library);
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
                                  color: isDark ? Colors.white : Colors.black,
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
                                style: TextStyle(color: Colors.red[400]),
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

  void _showEditLibraryDialog(Library library) {
    final isDark = context.isDark;
    final nameController = TextEditingController(text: library.name);
    final descController = TextEditingController(text: library.description);
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
                                  'Kütüphaneyi Düzenle',
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
                            labelText: 'Kütüphane Adı',
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
                                    await LibraryService()
                                        .updateLibrary(library.id, {
                                          'name': nameController.text,
                                          'description': descController.text,
                                        });
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      AppNotification.success(
                                        context,
                                        'Kütüphane güncellendi',
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      AppNotification.error(context, '$e');
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

  void _showCreateLibraryDialog() {
    final isDark = context.isDark;
    final nameController = TextEditingController();
    final descController = TextEditingController();
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
                                  PhosphorIconsRegular.books,
                                  color: context.primaryColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Yeni Kütüphane',
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
                          autofocus: true,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : AppColors.textLightPrimary,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Kütüphane Adı',
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
                                text: 'Oluştur',
                                onPressed: () async {
                                  if (nameController.text.isEmpty) {
                                    AppNotification.error(
                                      context,
                                      'Kütüphane adı gerekli',
                                    );
                                    return;
                                  }
                                  try {
                                    await LibraryService().createLibrary(
                                      name: nameController.text,
                                      description: descController.text.isEmpty
                                          ? null
                                          : descController.text,
                                    );
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      AppNotification.success(
                                        context,
                                        'Kütüphane oluşturuldu',
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      AppNotification.error(context, '$e');
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

  Future<void> _deleteLibraryWithUndo(Library library) async {
    if (library.isDefault) return;

    final libId = library.id;

    final confirmed = await showGlassConfirmDialog(
      context: context,
      title: 'Kütüphaneyi Sil',
      message: '"${library.name}" ve içindeki TÜM KİTAPLAR silinecek. Bu işlem geri alınamaz.',
      icon: PhosphorIconsRegular.trash,
      confirmText: 'Sil',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        await LibraryService().deleteLibrary(libId);
        if (mounted) {
          AppNotification.success(context, 'Kütüphane silindi');
        }
      } catch (e) {
        if (mounted) {
          AppNotification.error(context, '$e');
        }
      }
    }
  }
}
