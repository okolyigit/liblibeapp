import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/theme.dart';
import '../models/book.dart';
import '../models/reading_list.dart';
import '../services/book_service.dart';
import '../services/list_service.dart';
import '../screens/book_detail.dart';
import '../screens/list_detail.dart';

class UniversalSearchDelegate extends SearchDelegate {
  @override
  String get searchFieldLabel => 'Kitap veya liste ara...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final isDark = context.isDark;
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: context.surfaceColor,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : Colors.black38,
          fontSize: 16,
        ),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(PhosphorIconsRegular.x),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(PhosphorIconsRegular.caretLeft),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults(context);

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Aramaya başlayın...'));
    }

    final isDark = context.isDark;

    return FutureBuilder(
      future: Future.wait([
        BookService().searchBooks(query),
        ListService().searchLists(query),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
        }

        final results = snapshot.data as List<dynamic>?;
        final filteredBooks = (results?[0] as List<Book>?) ?? [];
        final filteredLists = (results?[1] as List<ReadingList>?) ?? [];

        if (filteredBooks.isEmpty && filteredLists.isEmpty) {
          return const Center(child: Text('Sonuç bulunamadı.'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (filteredBooks.isNotEmpty) ...[
              _buildSectionHeader(context, 'Kitaplar', isDark),
              ...filteredBooks.map(
                (book) => _buildBookResult(context, book, isDark),
              ),
              const SizedBox(height: 16),
            ],
            if (filteredLists.isNotEmpty) ...[
              _buildSectionHeader(context, 'Listeler', isDark),
              ...filteredLists.map(
                (list) => _buildListResult(context, list, isDark),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildBookResult(BuildContext context, Book book, bool isDark) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: context.subtleTint,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          PhosphorIconsFill.bookOpen,
          color: context.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        book.title,
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.textLightPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        book.author,
        style: TextStyle(
          color: isDark ? Colors.white60 : AppColors.textLightSecondary,
          fontSize: 12,
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
        );
      },
    );
  }

  Widget _buildListResult(BuildContext context, ReadingList list, bool isDark) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          list.id == 'favorites'
              ? PhosphorIconsFill.heart
              : PhosphorIconsFill.listBullets,
          color: list.id == 'favorites' ? Colors.red : Colors.blue,
          size: 20,
        ),
      ),
      title: Text(
        list.name,
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.textLightPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${list.bookCount} Kitap',
        style: TextStyle(
          color: isDark ? Colors.white60 : AppColors.textLightSecondary,
          fontSize: 12,
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ListDetailScreen(list: list)),
        );
      },
    );
  }
}
