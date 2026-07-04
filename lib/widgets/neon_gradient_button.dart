import 'package:flutter/material.dart';
import '../theme/theme.dart';

class NeonGradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double width;
  final double height;
  final bool isSecondary;
  final bool isDestructive;

  const NeonGradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width = double.infinity,
    this.height = 56,
    this.isSecondary = false,
    this.isDestructive = false,
  });

  @override
  State<NeonGradientButton> createState() => _NeonGradientButtonState();
}

class _NeonGradientButtonState extends State<NeonGradientButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // Only apply neon glow in dark modes
    final isDark = context.isDark;

    final baseGradient = LinearGradient(
      colors: widget.isSecondary 
          ? [context.surfaceColor, context.surfaceColor]
          : widget.isDestructive
              ? [Colors.red.shade400, Colors.red.shade600]
              : [AppColors.emerald, AppColors.lime],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          if (!widget.isLoading && widget.onPressed != null) {
            widget.onPressed!();
          }
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: widget.onPressed == null ? 0.5 : 1.0,
          child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width,
          height: widget.height,
          transform: Matrix4.translationValues(0, _isPressed ? 2 : (_isHovered ? -2 : 0), 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: baseGradient,
            border: widget.isSecondary 
                ? Border.all(
                    color: widget.isDestructive 
                        ? Colors.red.withValues(alpha: 0.5) 
                        : AppColors.emerald.withValues(alpha: 0.5)
                  ) 
                : null,
            boxShadow: (isDark && !widget.isSecondary) ? [
              BoxShadow(
                color: widget.isDestructive
                    ? Colors.red.withValues(alpha: _isHovered ? 0.6 : 0.4)
                    : AppColors.emerald.withValues(alpha: _isHovered ? 0.6 : 0.4),
                blurRadius: _isHovered ? 24 : 16,
                spreadRadius: _isHovered ? 4 : 0,
                offset: const Offset(0, 4),
              ),
            ] : null,
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: widget.isSecondary
                          ? (isDark ? Colors.white : Colors.black)
                          : Colors.black,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.text,
                        style: TextStyle(
                          color: widget.isSecondary ? (isDark ? Colors.white : Colors.black) : Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (widget.icon != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          widget.icon,
                          color: widget.isSecondary ? (isDark ? Colors.white : Colors.black) : Colors.black,
                          size: 20,
                        ),
                      ]
                    ],
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
