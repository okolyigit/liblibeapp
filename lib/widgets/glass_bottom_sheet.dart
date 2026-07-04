import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/theme.dart';
import 'neon_gradient_button.dart';

/// Standard glass-effect bottom sheet widget for form dialogs.
/// Provides consistent styling across the app with:
/// - Glass blur effect background
/// - Green-themed buttons (Vazgeç: outlined, Kaydet: filled)
/// - Proper keyboard padding
class GlassBottomSheet extends StatelessWidget {
  final String title;
  final IconData? titleIcon;
  final List<Widget> children;
  final String cancelText;
  final String confirmText;
  final VoidCallback? onCancel;
  final VoidCallback onConfirm;
  final bool isLoading;

  const GlassBottomSheet({
    super.key,
    required this.title,
    this.titleIcon,
    required this.children,
    this.cancelText = 'Vazgeç',
    this.confirmText = 'Kaydet',
    this.onCancel,
    required this.onConfirm,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
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
              children: [
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (titleIcon != null) ...[
                            Icon(
                              titleIcon,
                              color: context.primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                          ],
                          Text(
                            title,
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
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          onPressed: onCancel ?? () => Navigator.pop(context),
                          icon: Icon(
                            PhosphorIconsRegular.x,
                            size: 24,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    children: [
                      // Content
                      ...children,

                      const SizedBox(height: 32),

                      // Action buttons - Profile Edit style
                      Row(
                        children: [
                          // Vazgeç button - Outlined green
                          Expanded(
                            child: NeonGradientButton(
                              text: cancelText,
                              onPressed:
                                  onCancel ?? () => Navigator.pop(context),
                              isSecondary: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Kaydet button - Filled green
                          Expanded(
                            child: NeonGradientButton(
                              text: confirmText,
                              onPressed: onConfirm,
                              isLoading: isLoading,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper function to show a glass bottom sheet
Future<T?> showGlassBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: builder,
  );
}

/// Standard text field for bottom sheets
Widget buildBottomSheetTextField({
  required BuildContext context,
  required TextEditingController controller,
  required String label,
  String? hint,
  bool autofocus = false,
  int maxLines = 1,
  required bool isDark,
}) {
  return TextField(
    controller: controller,
    autofocus: autofocus,
    maxLines: maxLines,
    style: TextStyle(color: isDark ? Colors.white : AppColors.textLightPrimary),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: isDark ? Colors.white70 : AppColors.textLightSecondary,
      ),
      hintText: hint,
      hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.primaryColor, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
      ),
    ),
  );
}
