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

class UniversalSearchField extends StatefulWidget {
  final String hintText;
  final double width;

  const UniversalSearchField({
    super.key,
    this.hintText = "Kitap, Yazar, Liste Ara",
    this.width = 400,
  });

  @override
  State<UniversalSearchField> createState() => _UniversalSearchFieldState();
}

class _UniversalSearchFieldState extends State<UniversalSearchField> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _searchController.dispose();
    _hideOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      // Delay hide to allow click events to register
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_focusNode.hasFocus && mounted) {
          _hideOverlay();
        }
      });
    }
  }

  void _showOverlay() {
    _hideOverlay();
    final overlay = Overlay.of(context);
    _overlayEntry = _createOverlayEntry();
    overlay.insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 50),
          child: _buildResultsDropdown(),
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
                    _buildSectionHeader("KİTAPLAR"),
                    ...filteredBooks.map(
                      (book) => _buildResultItem(
                        context,
                        icon: PhosphorIconsFill.bookOpen,
                        title: book.title,
                        subtitle: book.author,
                        onTap: () {
                          _focusNode.unfocus();
                          _searchController.clear();
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
                    _buildSectionHeader("LİSTELER"),
                    ...filteredLists.map(
                      (list) => _buildResultItem(
                        context,
                        icon: list.id == 'favorites'
                            ? PhosphorIconsFill.heart
                            : PhosphorIconsFill.listBullets,
                        title: list.name,
                        subtitle: "${list.bookCount} Kitap",
                        onTap: () {
                          _focusNode.unfocus();
                          _searchController.clear();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ListDetailScreen(list: list),
                            ),
                          );
                        },
                        iconColor: list.id == 'favorites'
                            ? Colors.red
                            : context.primaryColor,
                      ),
                    ),
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
              color: context.surfaceColor.withValues(alpha: 0.9),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
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

  Widget _buildResultItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final effectiveIconColor =
        iconColor ?? Theme.of(context).colorScheme.primary;
    final isDark = context.isDark;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        width: widget.width,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
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
            prefixIcon: Icon(
              PhosphorIconsRegular.magnifyingGlass,
              size: 18,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                PhosphorIconsRegular.barcode,
                size: 20,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
                );
                if (result != null && result is String) {
                  _searchController.text = result;
                  if (_overlayEntry == null) _showOverlay();
                  _overlayEntry?.markNeedsBuild();
                }
              },
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onChanged: (v) {
            if (v.isNotEmpty && _overlayEntry == null) _showOverlay();
            _overlayEntry?.markNeedsBuild();
          },
        ),
      ),
    );
  }
}
