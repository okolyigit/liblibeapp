import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/theme.dart';

/// A consistent, centered error state with an icon, message and optional
/// "Tekrar dene" (retry) button. Use as a drop-in replacement for the ad-hoc
/// `Center(child: Text('Hata: ...'))` blocks inside StreamBuilder/FutureBuilder
/// error branches.
class ErrorStateView extends StatelessWidget {
  /// User-facing message. Defaults to a generic Turkish error line.
  final String message;

  /// Optional technical detail (e.g. `snapshot.error`) shown smaller below the
  /// message. Omitted when null.
  final String? detail;

  /// When provided, a retry button is shown that invokes this callback.
  final VoidCallback? onRetry;

  const ErrorStateView({
    super.key,
    this.message = 'Bir şeyler ters gitti',
    this.detail,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final secondary = isDark
        ? AppColors.textDarkSecondary
        : AppColors.textLightSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIconsRegular.warningCircle,
              size: 48,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textLightPrimary,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: secondary),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(PhosphorIconsRegular.arrowClockwise, size: 18),
                label: const Text('Tekrar dene'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
