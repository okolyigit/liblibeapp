import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme.dart';
import '../providers/app_data_provider.dart';

class GlassHero extends StatelessWidget {
  const GlassHero({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Consumer<AppDataProvider>(
      builder: (context, provider, child) {
        final stats = provider.userStats;
        final totalBooks = stats['total'] ?? 0;
        final readingBooks = stats['reading'] ?? 0;
        final completedBooks = stats['read'] ?? 0;

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          context.surfaceColor.withValues(alpha: 0.4),
                          context.surfaceColor.withValues(alpha: 0.6),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    context,
                    value: totalBooks,
                    label: 'Kitap',
                    isDark: isDark,
                  ),
                  _buildStatItem(
                    context,
                    value: readingBooks,
                    label: 'Okunuyor',
                    isDark: isDark,
                    highlight: true,
                  ),
                  _buildStatItem(
                    context,
                    value: completedBooks,
                    label: 'Okundu',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required int value,
    required String label,
    required bool isDark,
    bool highlight = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: highlight
                ? context.primaryColor
                : (isDark ? Colors.white : AppColors.textLightPrimary),
            height: 1,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: highlight
                ? context.primaryColor.withValues(alpha: 0.8)
                : (isDark
                      ? AppColors.textDarkSecondary
                      : AppColors.textLightSecondary),
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}
