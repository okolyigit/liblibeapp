import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/theme.dart';
import '../utils/book_filter_logic.dart';

/// Displays active filter chips that can be removed
class FilterChipsRow extends StatelessWidget {
  final BookFilterState filterState;
  final Function(BookFilterState) onFilterChanged;
  final EdgeInsetsGeometry padding;

  const FilterChipsRow({
    super.key,
    required this.filterState,
    required this.onFilterChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
  });

  @override
  Widget build(BuildContext context) {
    if (!filterState.hasActiveFilters) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          // Genre chips (multi-select)
          ...filterState.genres.map(
            (genre) => _buildChip(context, genre, () {
              final newGenres = List<String>.from(filterState.genres)
                ..remove(genre);
              onFilterChanged(filterState.copyWith(genres: newGenres));
            }),
          ),

          // Year chips (multi-select)
          ...filterState.years.map(
            (year) => _buildChip(context, year.toString(), () {
              final newYears = List<int>.from(filterState.years)..remove(year);
              onFilterChanged(filterState.copyWith(years: newYears));
            }),
          ),

          // Rating chips (multi-select)
          ...filterState.ratings.map(
            (rating) => _buildChip(context, '$rating â­', () {
              final newRatings = List<int>.from(filterState.ratings)
                ..remove(rating);
              onFilterChanged(filterState.copyWith(ratings: newRatings));
            }),
          ),

          // Sort chip (only if not default)
          if (filterState.sortBy != 'title')
            _buildChip(
              context,
              'Sıralama: ${getSortLabel(filterState.sortBy)}',
              () => onFilterChanged(filterState.copyWith(sortBy: 'title')),
            ),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.subtleTint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              PhosphorIconsBold.x,
              size: 14,
              color: context.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
