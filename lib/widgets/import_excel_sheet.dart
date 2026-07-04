import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/book.dart';
import '../services/excel_service.dart';
import '../services/book_service.dart';
import '../services/book_api_service.dart';
import '../theme/theme.dart';
import 'app_notification.dart';
import 'neon_gradient_button.dart';

class ImportExcelSheet extends StatefulWidget {
  final String libraryId;
  final List<Book> currentBooks;
  final VoidCallback onSuccess;

  const ImportExcelSheet({
    super.key,
    required this.libraryId,
    required this.currentBooks,
    required this.onSuccess,
  });

  @override
  State<ImportExcelSheet> createState() => _ImportExcelSheetState();
}

class _ImportExcelSheetState extends State<ImportExcelSheet> {
  final ExcelService _excelService = ExcelService();
  final BookService _bookService = BookService();
  final BookApiService _bookApiService = BookApiService();

  bool _isLoading = false;
  List<BookDraft>? _drafts;
  String? _fileName;
  String? _error;

  // Import statistics
  int _totalBooks = 0;
  int _skippedBooks = 0;
  int _newBooks = 0;
  String? _currentImportingTitle;

  Future<void> _pickFile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result != null) {
        final file = result.files.first;
        setState(() => _fileName = file.name);

        final drafts = await _excelService.parseExcel(file);

        setState(() {
          _drafts = drafts;
          _analyzeDrafts(drafts);
        });
      }
    } catch (e) {
      setState(() => _error = 'Dosya okunamadı: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _analyzeDrafts(List<BookDraft> drafts) {
    _totalBooks = drafts.length;
    _skippedBooks = 0;
    _newBooks = 0;

    for (var draft in drafts) {
      if (_isDuplicate(draft)) {
        _skippedBooks++;
      } else {
        _newBooks++;
      }
    }
  }

  bool _isDuplicate(BookDraft draft) {
    // Only check ISBN for duplicates (allows multiple editions/publishers of same title)
    if (draft.isbn != null && draft.isbn!.isNotEmpty) {
      return widget.currentBooks.any((b) => b.isbn == draft.isbn);
    }
    return false;
  }

  Future<void> _startImport() async {
    if (_drafts == null || _drafts!.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      int importedCount = 0;

      for (var draft in _drafts!) {
        if (_isDuplicate(draft)) continue;

        setState(() {
          _currentImportingTitle = 'Ekleniyor: ${draft.title}';
        });

        // Try to fetch cover URL
        String? coverUrl;
        String? subGenre;
        try {
          Map<String, dynamic>? bookData;

          if (draft.isbn != null && draft.isbn!.isNotEmpty) {
            bookData = await _bookApiService.searchByIsbn(draft.isbn!);
          }

          // If no ISBN or ISBN search failed
          bookData ??= await _bookApiService.searchBook(
            '${draft.title} ${draft.author}',
          );

          if (bookData != null) {
            coverUrl = bookData['coverUrl'];
            subGenre = bookData['genre'];
          }
        } catch (e) {
          debugPrint('Error fetching cover for ${draft.title}: $e');
        }

        await _bookService.addBook(
          libraryId: widget.libraryId,
          title: draft.title,
          author: draft.author,
          isbn: draft.isbn,
          publisher: draft.publisher,
          publishedDate: draft.publishedDate,
          pageCount: draft.pageCount,
          description: draft.description,
          genre: 'Diğer',
          subGenre: subGenre,
          coverUrl: coverUrl,
        );
        importedCount++;
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        AppNotification.success(
          context,
          '$importedCount kitap başarıyla eklendi.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'İçe aktarma hatası: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentImportingTitle = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.only(bottom: 24),
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
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
                              PhosphorIconsRegular.microsoftExcelLogo,
                              color: context.primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Excel ile İçe Aktar',
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
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_drafts == null && !_isLoading)
                      _buildUploadArea(isDark)
                    else if (_isLoading)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              color: context.primaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _currentImportingTitle ??
                                  'Kitap kapağı ve bilgileri alınıyor...',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.textLightSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      _buildPreviewArea(isDark),

                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadArea(bool isDark) {
    return InkWell(
      onTap: _pickFile,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.primaryColor.withValues(alpha: 0.3),
            width: 2,
            style: BorderStyle.none,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIconsRegular.microsoftExcelLogo,
              size: 48,
              color: context.primaryColor,
            ),
            const SizedBox(height: 12),
            Text(
              'Excel dosyasını seçin (.xlsx)',
              style: TextStyle(
                color: isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textLightSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewArea(bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Icon(PhosphorIconsRegular.fileXls, color: context.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _fileName ?? 'Dosya',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textLightPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: () => setState(() {
                _drafts = null;
                _fileName = null;
              }),
              icon: Icon(
                PhosphorIconsRegular.x,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 12),
        _buildStatRow('Toplam Kitap', _totalBooks.toString(), null, isDark),
        _buildStatRow('Eklenecek', _newBooks.toString(), Colors.green),
        _buildStatRow(
          'Atlanacak (Mevcut)',
          _skippedBooks.toString(),
          Colors.orange,
        ),
        const SizedBox(height: 24),
        NeonGradientButton(
          onPressed: _newBooks > 0 ? () => _startImport() : null,
          text: 'İçe Aktarmayı Başlat',
        ),
      ],
    );
  }

  Widget _buildStatRow(
    String label,
    String value, [
    Color? valueColor,
    bool isDark = false,
  ]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark
                  ? AppColors.textDarkSecondary
                  : AppColors.textLightSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color:
                  valueColor ??
                  (isDark ? Colors.white : AppColors.textLightPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
