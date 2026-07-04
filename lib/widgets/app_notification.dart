import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/theme.dart';

/// Notification types for different message styles
enum NotificationType { success, error, warning, info }

/// Custom styled notification helper for the app
/// Shows notifications at the BOTTOM of the screen with glass design
class AppNotification {
  static OverlayEntry? _currentOverlay;
  static Timer? _dismissTimer;

  /// Show a styled notification at the BOTTOM of the screen
  static void show(
    BuildContext context, {
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? action,
    String? actionLabel,
  }) {
    // Dismiss any existing notification
    _dismiss();

    final isDark = context.isDark;
    final overlay = Overlay.of(context);

    // Get icon and accent color based on type
    final (Color accentColor, IconData icon) = switch (type) {
      NotificationType.success => (
        context.primaryColor,
        PhosphorIconsFill.checkCircle,
      ),
      NotificationType.error => (Colors.red[400]!, PhosphorIconsFill.xCircle),
      NotificationType.warning => (
        Colors.amber[600]!,
        PhosphorIconsFill.warning,
      ),
      NotificationType.info => (Colors.blue[400]!, PhosphorIconsFill.info),
    };

    _currentOverlay = OverlayEntry(
      builder: (context) => _BottomNotificationWidget(
        message: message,
        accentColor: accentColor,
        icon: icon,
        isDark: isDark,
        action: action,
        actionLabel: actionLabel,
        onDismiss: _dismiss,
      ),
    );

    overlay.insert(_currentOverlay!);

    // Auto dismiss after duration
    _dismissTimer = Timer(duration, _dismiss);
  }

  static void _dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  /// Convenience method for success messages
  static void success(BuildContext context, String message) {
    show(context, message: message, type: NotificationType.success);
  }

  /// Convenience method for error messages
  static void error(BuildContext context, String message) {
    show(context, message: message, type: NotificationType.error);
  }

  /// Convenience method for warning messages
  static void warning(BuildContext context, String message) {
    show(context, message: message, type: NotificationType.warning);
  }

  /// Convenience method for info messages
  static void info(BuildContext context, String message) {
    show(context, message: message, type: NotificationType.info);
  }
}

/// Internal widget for the bottom notification popup with glass design
class _BottomNotificationWidget extends StatefulWidget {
  final String message;
  final Color accentColor;
  final IconData icon;
  final bool isDark;
  final VoidCallback? action;
  final String? actionLabel;
  final VoidCallback onDismiss;

  const _BottomNotificationWidget({
    required this.message,
    required this.accentColor,
    required this.icon,
    required this.isDark,
    required this.onDismiss,
    this.action,
    this.actionLabel,
  });

  @override
  State<_BottomNotificationWidget> createState() =>
      _BottomNotificationWidgetState();
}

class _BottomNotificationWidgetState extends State<_BottomNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    // Slide from bottom
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final topPadding = MediaQuery.of(context).padding.top;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;

    Widget notificationContent = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: widget.onDismiss,
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null &&
                    details.primaryVelocity!.abs() > 100) {
                  widget.onDismiss();
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? AppColors.bgDarkSurface.withValues(alpha: 0.85)
                          : Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: widget.isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : context.primaryColor.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: widget.accentColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.icon,
                            color: widget.accentColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: TextStyle(
                              color: widget.isDark
                                  ? Colors.white
                                  : AppColors.textLightPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (widget.action != null && widget.actionLabel != null)
                          TextButton(
                            onPressed: () {
                              widget.onDismiss();
                              widget.action!();
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            child: Text(
                              widget.actionLabel!,
                              style: TextStyle(
                                color: widget.accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // When keyboard is open, show at TOP of screen instead of bottom
    if (isKeyboardOpen) {
      return Positioned(
        top: topPadding + 16,
        left: 16,
        right: 16,
        child: Center(child: notificationContent),
      );
    }

    // Normal case: show at bottom above the nav bar
    return Positioned(
      bottom: bottomPadding + 100,
      left: 16,
      right: 16,
      child: Center(child: notificationContent),
    );
  }
}
