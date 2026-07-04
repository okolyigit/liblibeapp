import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/theme.dart';
import '../models/library.dart';
import '../services/library_service.dart';

/// A custom library dropdown that opens below the button and doesn't cover the selected item.
class LibraryDropdown extends StatefulWidget {
  final String? selectedLibraryId;
  final Function(String) onChanged;
  final bool showSharedLibraries;

  const LibraryDropdown({
    super.key,
    required this.selectedLibraryId,
    required this.onChanged,
    this.showSharedLibraries = true,
  });

  @override
  State<LibraryDropdown> createState() => _LibraryDropdownState();
}

class _LibraryDropdownState extends State<LibraryDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  // Cache for owner names
  final Map<String, String> _ownerNamesCache = {};

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isOpen = false);
  }

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Full screen tap barrier to close dropdown
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDropdown,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Dropdown content positioned below the button - same width as button
          Positioned(
            width: size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 4),
              child: Material(
                color: Colors.transparent,
                child: _LibraryDropdownContent(
                  selectedLibraryId: widget.selectedLibraryId,
                  ownerNamesCache: _ownerNamesCache,
                  showSharedLibraries: widget.showSharedLibraries,
                  onOwnerNameFetched: (userId, name) {
                    _ownerNamesCache[userId] = name;
                  },
                  onSelected: (libraryId) {
                    widget.onChanged(libraryId);
                    _closeDropdown();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return CompositedTransformTarget(
      link: _layerLink,
      child: StreamBuilder<List<Library>>(
        stream: LibraryService().getUserLibraries(),
        builder: (context, snapshot) {
          final libraries = snapshot.data ?? [];
          final selectedLibrary = libraries.cast<Library?>().firstWhere(
            (l) => l?.id == widget.selectedLibraryId,
            orElse: () => null,
          );

          final currentUserId = LibraryService().currentUserId;
          final isShared =
              selectedLibrary != null &&
              selectedLibrary.ownerId != currentUserId;

          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _toggleDropdown,
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: context.surfaceColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isOpen
                        ? context.primaryColor
                        : (isDark ? Colors.white10 : Colors.black12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      PhosphorIconsRegular.books,
                      size: 16,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: isShared
                          ? FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(selectedLibrary.ownerId)
                                  .get(),
                              builder: (context, snapshot) {
                                String displayName = selectedLibrary.name;
                                if (snapshot.hasData && snapshot.data!.exists) {
                                  final name =
                                      snapshot.data!.get('displayName')
                                          as String? ??
                                      'Bir kullanıcı';
                                  displayName =
                                      '${selectedLibrary.name} - $name';
                                }
                                return Text(
                                  displayName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            )
                          : Text(
                              selectedLibrary?.name ?? 'Kütüphane Seç',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _isOpen ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        PhosphorIconsRegular.caretDown,
                        size: 16,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LibraryDropdownContent extends StatelessWidget {
  final String? selectedLibraryId;
  final Map<String, String> ownerNamesCache;
  final Function(String userId, String name) onOwnerNameFetched;
  final Function(String libraryId) onSelected;
  final bool showSharedLibraries;

  const _LibraryDropdownContent({
    required this.selectedLibraryId,
    required this.ownerNamesCache,
    required this.onOwnerNameFetched,
    required this.onSelected,
    this.showSharedLibraries = true,
  });

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

  Color _getColor(BuildContext context, String? colorHex) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final currentUserId = LibraryService().currentUserId;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.bgDarkSurface.withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.primaryColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: StreamBuilder<List<Library>>(
            stream: LibraryService().getUserLibraries(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final libraries = snapshot.data!;
              if (libraries.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Kütüphane bulunamadı',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                );
              }

              // Separate owned and shared libraries
              final ownedLibs = libraries
                  .where((l) => l.ownerId == currentUserId)
                  .toList();
              final sharedLibs = libraries
                  .where((l) => l.ownerId != currentUserId)
                  .toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Owned libraries
                    ...ownedLibs.map(
                      (lib) => _buildLibraryItem(
                        context,
                        lib,
                        isOwner: true,
                        isSelected: lib.id == selectedLibraryId,
                        isDark: isDark,
                      ),
                    ),

                    // Shared libraries section (only if allowed)
                    if (showSharedLibraries && sharedLibs.isNotEmpty) ...[
                      _buildSectionDivider('Paylaşılan Kütüphaneler', isDark),
                      ...sharedLibs.map(
                        (lib) => _buildLibraryItem(
                          context,
                          lib,
                          isOwner: false,
                          isSelected: lib.id == selectedLibraryId,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionDivider(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: isDark ? Colors.white12 : Colors.black12,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
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

  Widget _buildLibraryItem(
    BuildContext context,
    Library library, {
    required bool isOwner,
    required bool isSelected,
    required bool isDark,
  }) {
    final color = _getColor(context, library.color);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onSelected(library.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? context.primaryColor.withValues(alpha: isDark ? 0.2 : 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Library icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_getIcon(library.icon), color: color, size: 20),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: isOwner
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            library.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isDark
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
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      )
                    : FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(library.ownerId)
                            .get(),
                        builder: (context, snapshot) {
                          String ownerName =
                              ownerNamesCache[library.ownerId] ??
                              'Yükleniyor...';

                          if (snapshot.hasData && snapshot.data!.exists) {
                            ownerName =
                                snapshot.data!.get('displayName') as String? ??
                                snapshot.data!.get('email') as String? ??
                                'Bir kullanıcı';
                            // Cache it
                            if (!ownerNamesCache.containsKey(library.ownerId)) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                onOwnerNameFetched(library.ownerId, ownerName);
                              });
                            }
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                library.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textLightPrimary,
                                ),
                              ),
                              Text(
                                '$ownerName tarafından paylaşıldı',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          );
                        },
                      ),
              ),
              // Checkmark for selected
              if (isSelected)
                Icon(
                  PhosphorIconsFill.checkCircle,
                  color: context.primaryColor,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
