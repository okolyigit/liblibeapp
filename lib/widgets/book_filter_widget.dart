import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/theme.dart';
import '../utils/book_filter_logic.dart';
import '../models/book.dart';

/// Reusable filter widget that shows a bottom sheet with filter options
class BookFilterWidget extends StatelessWidget {
  final BookFilterState filterState;
  final Function(BookFilterState) onFilterChanged;
  final List<Book> availableBooks; // For getting available genres/years
  final bool showGenreFilter;
  final bool showYearFilter;
  final bool showRatingFilter;

  const BookFilterWidget({
    super.key,
    required this.filterState,
    required this.onFilterChanged,
    required this.availableBooks,
    this.showGenreFilter = true,
    this.showYearFilter = true,
    this.showRatingFilter = true,
  });

  void showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BookFilterSheetContent(
        filterState: filterState,
        onFilterChanged: onFilterChanged,
        availableBooks: availableBooks,
        showGenreFilter: showGenreFilter,
        showYearFilter: showYearFilter,
        showRatingFilter: showRatingFilter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This widget is typically used via showFilterSheet method
    // Direct widget use shows filter icon button
    final isDark = context.isDark;
    return IconButton(
      onPressed: () => showFilterSheet(context),
      icon: Icon(
        PhosphorIconsRegular.funnelSimple,
        color: isDark ? Colors.white : AppColors.textLightPrimary,
      ),
    );
  }
}

class BookFilterSheetContent extends StatefulWidget {
  final BookFilterState filterState;
  final Function(BookFilterState) onFilterChanged;
  final List<Book> availableBooks;
  final bool showGenreFilter;
  final bool showYearFilter;
  final bool showRatingFilter;

  const BookFilterSheetContent({
    super.key,
    required this.filterState,
    required this.onFilterChanged,
    required this.availableBooks,
    this.showGenreFilter = true,
    this.showYearFilter = true,
    this.showRatingFilter = true,
  });

  @override
  State<BookFilterSheetContent> createState() => _BookFilterSheetContentState();
}

class _BookFilterSheetContentState extends State<BookFilterSheetContent> {
  late BookFilterState localFilter;

  @override
  void initState() {
    super.initState();
    localFilter = widget.filterState;
  }

  void updateFilter(BookFilterState newState) {
    setState(() {
      localFilter = newState;
    });
    widget.onFilterChanged(newState);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final genres = getAvailableGenres(widget.availableBooks);
    final years = getAvailableYears(widget.availableBooks);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      Theme.of(
                        context,
                      ).scaffoldBackgroundColor.withValues(alpha: 0.8),
                      Theme.of(
                        context,
                      ).scaffoldBackgroundColor.withValues(alpha: 0.95),
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with handle and close button - NOW FIXED (Outside ScrollView)
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  margin: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      'Filtreleme',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : AppColors.textLightPrimary,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          PhosphorIconsRegular.x,
                          size: 24,
                          color: isDark
                              ? Colors.white70
                              : AppColors.textLightSecondary,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Genre Filter
                      if (widget.showGenreFilter && genres.isNotEmpty) ...[
                        _buildSectionTitle("Tür", isDark),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildFilterChip(
                              null,
                              'Tümü',
                              localFilter.genres.isEmpty,
                              isDark,
                              (selected) {
                                updateFilter(
                                  localFilter.copyWith(clearGenres: true),
                                );
                              },
                            ),
                            ...genres.map(
                              (genre) => _buildFilterChip(
                                genre,
                                genre,
                                localFilter.genres.contains(genre),
                                isDark,
                                (selected) {
                                  final newGenres = List<String>.from(
                                    localFilter.genres,
                                  );
                                  if (selected) {
                                    newGenres.add(genre);
                                  } else {
                                    newGenres.remove(genre);
                                  }
                                  updateFilter(
                                    localFilter.copyWith(genres: newGenres),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Year Filter
                      if (widget.showYearFilter && years.isNotEmpty) ...[
                        _buildSectionTitle("Yıl", isDark),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildFilterChip(
                              null,
                              'Tümü',
                              localFilter.years.isEmpty,
                              isDark,
                              (selected) {
                                updateFilter(
                                  localFilter.copyWith(clearYears: true),
                                );
                              },
                            ),
                            ...years.map(
                              (year) => _buildFilterChip(
                                year,
                                year.toString(),
                                localFilter.years.contains(year),
                                isDark,
                                (selected) {
                                  final newYears = List<int>.from(
                                    localFilter.years,
                                  );
                                  if (selected) {
                                    newYears.add(year);
                                  } else {
                                    newYears.remove(year);
                                  }
                                  updateFilter(
                                    localFilter.copyWith(years: newYears),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Rating Filter
                      if (widget.showRatingFilter) ...[
                        _buildSectionTitle("Puan", isDark),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildFilterChip(
                              null,
                              'Tümü',
                              localFilter.ratings.isEmpty,
                              isDark,
                              (selected) {
                                updateFilter(
                                  localFilter.copyWith(clearRatings: true),
                                );
                              },
                            ),
                            ...List.generate(5, (i) => 5 - i).map(
                              (rating) => _buildRatingChip(
                                rating,
                                localFilter.ratings.contains(rating),
                                isDark,
                                (selected) {
                                  final newRatings = List<int>.from(
                                    localFilter.ratings,
                                  );
                                  if (selected) {
                                    newRatings.add(rating);
                                  } else {
                                    newRatings.remove(rating);
                                  }
                                  updateFilter(
                                    localFilter.copyWith(ratings: newRatings),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Categories Filter
                      if (getAvailableCategories(
                        widget.availableBooks,
                      ).isNotEmpty) ...[
                        _buildSectionTitle("Etiketler", isDark),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...getAvailableCategories(
                              widget.availableBooks,
                            ).map((cat) {
                              final isSelected = localFilter.selectedCategories
                                  .contains(cat);
                              return _buildFilterChip(
                                cat,
                                cat,
                                isSelected,
                                isDark,
                                (selected) {
                                  final newCats = List<String>.from(
                                    localFilter.selectedCategories,
                                  );
                                  if (selected) {
                                    newCats.add(cat);
                                  } else {
                                    newCats.remove(cat);
                                  }
                                  updateFilter(
                                    localFilter.copyWith(
                                      selectedCategories: newCats,
                                    ),
                                  );
                                },
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                      const SizedBox(height: 32),

                      // Reset Button
                      Center(
                        child: Opacity(
                          opacity: localFilter.hasActiveFilters ? 1.0 : 0.0,
                          child: IgnorePointer(
                            ignoring: !localFilter.hasActiveFilters,
                            child: TextButton.icon(
                              onPressed: () {
                                updateFilter(localFilter.reset());
                              },
                              icon: const Icon(
                                PhosphorIconsRegular.arrowCounterClockwise,
                              ),
                              label: const Text("Filtreleri Sıfırla"),
                              style: TextButton.styleFrom(
                                foregroundColor: context.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Add extra bottom padding for safe area
                      SizedBox(
                        height: MediaQuery.of(context).viewPadding.bottom + 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : AppColors.textLightPrimary,
      ),
    );
  }

  Widget _buildFilterChip(
    dynamic value,
    String label,
    bool isSelected,
    bool isDark,
    Function(bool) onSelected,
  ) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: context.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: context.primaryColor,
      labelStyle: TextStyle(
        color: isSelected
            ? context.primaryColor
            : (isDark ? Colors.white70 : AppColors.textLightSecondary),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      backgroundColor: context.surfaceColor,
      side: BorderSide(
        color: isSelected
            ? context.primaryColor
            : (isDark
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.2)),
        width: 1.0,
      ),
      onSelected: onSelected,
    );
  }

  Widget _buildRatingChip(
    int rating,
    bool isSelected,
    bool isDark,
    Function(bool) onSelected,
  ) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$rating'),
          const SizedBox(width: 4),
          Icon(
            PhosphorIconsFill.star,
            size: 14,
            color: isSelected ? context.primaryColor : Colors.amber,
          ),
          const Text('+'),
        ],
      ),
      selected: isSelected,
      selectedColor: context.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: context.primaryColor,
      backgroundColor: context.surfaceColor,
      side: BorderSide(
        color: isSelected
            ? context.primaryColor
            : (isDark
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.2)),
        width: 1.0,
      ),
      onSelected: onSelected,
    );
  }
}
