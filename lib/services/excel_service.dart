import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/book.dart';

class BookDraft {
  final String title;
  final String author;
  final String? isbn;
  final String? publisher;
  final String? publishedDate;
  final int? pageCount;
  final String? description;
  final int rating;
  final String? userNotes;

  BookDraft({
    required this.title,
    required this.author,
    this.isbn,
    this.publisher,
    this.publishedDate,
    this.pageCount,
    this.description,
    required this.rating,
    this.userNotes,
  });
}

class ExcelService {
  // Column Headers
  static const _colTitle = 'Title';
  static const _colAuthor = 'Author';
  static const _colISBN = 'ISBN';
  static const _colPublisher = 'Publisher';
  static const _colPublishedDate = 'Published Date';
  static const _colPageCount = 'Page Count';
  static const _colDescription = 'Description';
  static const _colRating = 'Rating';
  static const _colNotes = 'Notes';

  static const List<String> _headers = [
    _colTitle,
    _colAuthor,
    _colISBN,
    _colPublisher,
    _colPublishedDate,
    _colPageCount,
    _colDescription,
    _colRating,
    _colNotes,
  ];

  /// Generate Excel file bytes from a list of books
  Future<List<int>?> generateExcel(List<Book> books) async {
    try {
      var excel = Excel.createExcel();
      // Rename default sheet
      var sheetName = 'Library Export';
      excel.rename('Sheet1', sheetName);

      Sheet sheetObject = excel[sheetName];

      // Add Headers
      sheetObject.appendRow(_headers.map((e) => TextCellValue(e)).toList());

      // Add Data
      for (var book in books) {
        sheetObject.appendRow([
          TextCellValue(book.title),
          TextCellValue(book.author),
          TextCellValue(book.isbn ?? ''),
          TextCellValue(book.publisher ?? ''),
          TextCellValue(book.publishedDate ?? ''),
          IntCellValue(book.pageCount ?? 0),
          TextCellValue(book.description ?? ''),
          IntCellValue(book.rating),
          TextCellValue(book.userNotes ?? ''),
        ]);
      }

      return excel.encode();
    } catch (e) {
      debugPrint('Error generating Excel: $e');
      return null;
    }
  }

  /// Parse Excel file and return list of valid book drafts
  Future<List<BookDraft>> parseExcel(PlatformFile file) async {
    List<BookDraft> drafts = [];
    try {
      var bytes = file.bytes;
      if (bytes == null && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }

      if (bytes == null) return [];

      var excel = Excel.decodeBytes(bytes);

      // Assume data is in the first available table
      if (excel.tables.isEmpty) return [];

      var table = excel.tables.values.first;

      // Check headers
      if (table.rows.isEmpty) return [];
      var headerRow = table.rows.first;

      // Create index map for columns (in case order changes)
      Map<String, int> colIndex = {};
      for (var i = 0; i < headerRow.length; i++) {
        var cell = headerRow[i];
        if (cell != null && cell.value != null) {
          colIndex[cell.value.toString()] = i;
        }
      }

      // Read data rows (skip first row)
      for (var i = 1; i < table.rows.length; i++) {
        var row = table.rows[i];
        if (row.isEmpty) continue;

        String title = _getCellValue(row, colIndex[_colTitle]);
        String author = _getCellValue(row, colIndex[_colAuthor]);

        // Minimal requirement check
        if (title.isEmpty || author.isEmpty) continue;

        drafts.add(
          BookDraft(
            title: title,
            author: author,
            isbn: _getCellValue(row, colIndex[_colISBN]),
            publisher: _getCellValue(row, colIndex[_colPublisher]),
            publishedDate: _getCellValue(row, colIndex[_colPublishedDate]),
            pageCount:
                int.tryParse(_getCellValue(row, colIndex[_colPageCount])) ?? 0,
            description: _getCellValue(row, colIndex[_colDescription]),
            rating: int.tryParse(_getCellValue(row, colIndex[_colRating])) ?? 0,
            userNotes: _getCellValue(row, colIndex[_colNotes]),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error parsing Excel: $e');
    }
    return drafts;
  }

  /// Save and share the file (Mobile way)
  Future<void> saveAndShareFile(String fileName, List<int> bytes) async {
    if (kIsWeb) {
      try {
        await FilePicker.platform.saveFile(
          dialogTitle: 'Excel Dosyasını Kaydet',
          fileName: fileName,
          bytes: Uint8List.fromList(bytes),
        );
      } catch (e) {
        debugPrint('Web save error: $e');
      }
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/$fileName';
      final file = File(path);
      await file.writeAsBytes(bytes);

      // Share the file
      await Share.shareXFiles([XFile(path)], text: 'İşte kitap listeniz!');
    } catch (e) {
      debugPrint('Error saving/sharing file: $e');
    }
  }

  String _getCellValue(List<Data?> row, int? index) {
    if (index == null || index < 0 || index >= row.length) return '';
    var cell = row[index];
    if (cell == null) return '';
    return cell.value.toString();
  }

}
