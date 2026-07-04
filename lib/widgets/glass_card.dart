import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 20.0, // Web uses 20px blur
    this.color,
    this.borderRadius,
    this.padding,
    this.margin,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    
    // Falls back to theme card color or specific glass tokens
    final effectiveColor =
        color ?? (isDark ? AppColors.glassBgDark : AppColors.glassBgLight);
        
    final effectiveBorderRadius =
        borderRadius ??
        (Theme.of(context).cardTheme.shape as RoundedRectangleBorder?)
            ?.borderRadius ??
        BorderRadius.circular(24);

    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: effectiveBorderRadius as BorderRadius,
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: effectiveColor,
              borderRadius: effectiveBorderRadius,
              border: Border.all(
                color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
                width: 1.0,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
