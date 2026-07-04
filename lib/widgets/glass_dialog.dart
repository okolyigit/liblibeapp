import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'neon_gradient_button.dart';

/// Standard glass-effect dialog widget for confirmations and alerts.
/// Provides consistent styling across the app with:
/// - Glass blur effect background
/// - Themed buttons (Cancel: secondary, Confirm: primary gradient)
/// - Destructive mode for delete confirmations
class GlassDialog extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget content;
  final String? cancelText;
  final String confirmText;
  final VoidCallback? onCancel;
  final VoidCallback onConfirm;
  final bool isDestructive;
  final bool isLoading;
  final bool barrierDismissible;

  const GlassDialog({
    super.key,
    required this.title,
    this.icon,
    required this.content,
    this.cancelText,
    this.confirmText = 'Tamam',
    this.onCancel,
    required this.onConfirm,
    this.isDestructive = false,
    this.isLoading = false,
    this.barrierDismissible = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AlertDialog(
          backgroundColor: isDark
              ? context.surfaceColor.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark
                  ? AppColors.glassBorderDark
                  : AppColors.glassBorderLight,
              width: 1,
            ),
          ),
          title: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: isDestructive ? Colors.red : context.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textLightPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: content,
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          actions: [
            Row(
              children: [
                if (cancelText != null) ...[
                  Expanded(
                    child: NeonGradientButton(
                      text: cancelText!,
                      isSecondary: true,
                      height: 48,
                      onPressed: onCancel ?? () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: NeonGradientButton(
                    text: confirmText,
                    isDestructive: isDestructive,
                    isLoading: isLoading,
                    height: 48,
                    onPressed: onConfirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper function to show a glass dialog
Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required String title,
  IconData? icon,
  required Widget content,
  String? cancelText,
  String confirmText = 'Tamam',
  VoidCallback? onCancel,
  required VoidCallback onConfirm,
  bool isDestructive = false,
  bool isLoading = false,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => GlassDialog(
      title: title,
      icon: icon,
      content: content,
      cancelText: cancelText,
      confirmText: confirmText,
      onCancel: onCancel,
      onConfirm: onConfirm,
      isDestructive: isDestructive,
      isLoading: isLoading,
      barrierDismissible: barrierDismissible,
    ),
  );
}

/// Simple info/error/success dialog helper
Future<void> showGlassInfoDialog({
  required BuildContext context,
  required String title,
  required String message,
  IconData? icon,
  String confirmText = 'Tamam',
}) {
  return showGlassDialog(
    context: context,
    title: title,
    icon: icon,
    content: Text(
      message,
      style: TextStyle(
        color: context.isDark
            ? Colors.white70
            : AppColors.textLightSecondary,
      ),
    ),
    confirmText: confirmText,
    onConfirm: () => Navigator.pop(context),
  );
}

/// Confirmation dialog that returns bool
Future<bool?> showGlassConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  IconData? icon,
  String cancelText = 'Vazgeç',
  String confirmText = 'Onayla',
  bool isDestructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => GlassDialog(
      title: title,
      icon: icon,
      content: Text(
        message,
        style: TextStyle(
          color: context.isDark
              ? Colors.white70
              : AppColors.textLightSecondary,
        ),
      ),
      cancelText: cancelText,
      confirmText: confirmText,
      isDestructive: isDestructive,
      onCancel: () => Navigator.pop(context, false),
      onConfirm: () => Navigator.pop(context, true),
    ),
  );
}
