import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/theme.dart';
import '../services/activity_service.dart';

/// A glassmorphism-styled monthly reading calendar widget.
/// Shows the current month with green dots on days when books were read.
/// Allows navigation to previous/next months.
class ReadingCalendar extends StatefulWidget {
  const ReadingCalendar({super.key});

  @override
  State<ReadingCalendar> createState() => _ReadingCalendarState();
}

class _ReadingCalendarState extends State<ReadingCalendar> {
  late DateTime _displayedMonth;

  Stream<Set<DateTime>>? _activityStream;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
    _updateActivityStream();
  }

  void _updateActivityStream() {
    _activityStream = ActivityService().getReadingDaysForMonth(
      _displayedMonth.year,
      _displayedMonth.month,
    );
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
        1,
      );
      _updateActivityStream();
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    final nextMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + 1,
      1,
    );
    // Don't allow going past current month
    if (nextMonth.year < now.year ||
        (nextMonth.year == now.year && nextMonth.month <= now.month)) {
      setState(() {
        _displayedMonth = nextMonth;
        _updateActivityStream();
      });
    }
  }

  bool _canGoNext() {
    final now = DateTime.now();
    return _displayedMonth.year < now.year ||
        (_displayedMonth.year == now.year && _displayedMonth.month < now.month);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + 1,
      0,
    );
    final daysInMonth = lastDayOfMonth.day;

    // Calculate what day of week the month starts (0 = Monday in our grid)
    final startWeekday = firstDayOfMonth.weekday - 1; // 0-indexed

    // Turkish weekday abbreviations
    final weekDays = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz'];

    // Turkish month names
    final monthNames = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          (Theme.of(
                                context,
                              ).cardTheme.color?.withValues(alpha: 0.4) ??
                              context.surfaceColor.withValues(alpha: 0.4)),
                          (Theme.of(
                                context,
                              ).cardTheme.color?.withValues(alpha: 0.6) ??
                              context.surfaceColor.withValues(alpha: 0.6)),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.7),
                          Colors.white.withValues(alpha: 0.9),
                        ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? context.primaryColor.withValues(alpha: 0.2)
                      : context.primaryColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.primaryColor.withValues(
                      alpha: isDark ? 0.1 : 0.15,
                    ),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: StreamBuilder<Set<DateTime>>(
                stream: _activityStream,
                builder: (context, snapshot) {
                  final readingDays = snapshot.data ?? <DateTime>{};

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Month header with navigation arrows
                      Row(
                        children: [
                          // Previous month arrow
                          GestureDetector(
                            onTap: _previousMonth,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                PhosphorIconsRegular.caretLeft,
                                size: 20,
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.textLightSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Month/Year text
                          Expanded(
                            child: Text(
                              '${monthNames[_displayedMonth.month - 1]} ${_displayedMonth.year}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textLightPrimary,
                              ),
                            ),
                          ),
                          // Reading days count badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: context.subtleTint,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_getReadingDaysThisMonth(readingDays)} gün',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Next month arrow
                          GestureDetector(
                            onTap: _canGoNext() ? _nextMonth : null,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                PhosphorIconsRegular.caretRight,
                                size: 20,
                                color: _canGoNext()
                                    ? (isDark
                                          ? Colors.white70
                                          : AppColors.textLightSecondary)
                                    : (isDark
                                          ? Colors.white24
                                          : Colors.black12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Weekday headers
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: weekDays.map((day) {
                          return SizedBox(
                            width: 32,
                            child: Center(
                              child: Text(
                                day,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.textDarkSecondary
                                      : AppColors.textLightSecondary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),

                      // Calendar grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              childAspectRatio: 1,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                            ),
                        itemCount: startWeekday + daysInMonth,
                        itemBuilder: (context, index) {
                          // Empty cells before month starts
                          if (index < startWeekday) {
                            return const SizedBox();
                          }

                          final day = index - startWeekday + 1;
                          final date = DateTime(
                            _displayedMonth.year,
                            _displayedMonth.month,
                            day,
                          );
                          final isToday =
                              _displayedMonth.year == now.year &&
                              _displayedMonth.month == now.month &&
                              day == now.day;
                          final hasReading = _hasReadingOnDay(
                            date,
                            readingDays,
                          );

                          return _buildDayCell(
                            context,
                            day: day,
                            isToday: isToday,
                            hasReading: hasReading,
                            isDark: isDark,
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayCell(
    BuildContext context, {
    required int day,
    required bool isToday,
    required bool hasReading,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isToday ? context.mediumTint : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isToday
            ? Border.all(color: context.primaryColor, width: 1.5)
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '$day',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
              color: isToday
                  ? context.primaryColor
                  : (isDark ? Colors.white70 : AppColors.textLightPrimary),
            ),
          ),
          // Green dot for reading days
          if (hasReading)
            Positioned(
              bottom: 4,
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: context.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _hasReadingOnDay(DateTime date, Set<DateTime> readingDays) {
    return readingDays.any(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );
  }

  int _getReadingDaysThisMonth(Set<DateTime> readingDays) {
    return readingDays
        .where(
          (d) =>
              d.year == _displayedMonth.year &&
              d.month == _displayedMonth.month,
        )
        .length;
  }
}
