import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Standardized glass header used across all main screens.
///
/// Renders a blurred, tinted bar that sits above the scrollable content
/// (typically inside a Stack with `Positioned(top: 0, left: 0, right: 0, ...)`).
///
/// The top row hosts [leading] (optional), [title] and [actions] (optional).
/// An additional [bottom] widget can be stacked underneath for toolbars,
/// chip rows, segmented controls, etc. — it shares the same glass surface.
///
/// Scroll-aware behavior: pass a [scrollController] tied to the primary
/// scrollable below. When offset > [_scrollBorderThreshold], a hairline
/// bottom border fades in (iOS/Material 3 "elevated on scroll" pattern).
/// When no controller is provided, the border is always hidden.
///
/// Status bar handling: this widget reads the physical status bar height
/// from the window (via `viewPadding.top` — not `padding.top`, which
/// SystemUiMode.edgeToEdge zeroes on Android) and adds it to the top
/// padding. Place the header at `Positioned(top: 0)` in a Stack that is
/// the direct child of Scaffold.body (not inside a top-facing SafeArea),
/// so "top: 0" maps to the true screen top on every platform. The header's
/// blur/gradient then covers the status bar region, and title content sits
/// below the system icons.
class AppHeader extends StatefulWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? bottom;
  final double titleSize;
  final EdgeInsetsGeometry? padding;
  final double blurSigma;
  final ScrollController? scrollController;

  const AppHeader({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.bottom,
    this.titleSize = 22,
    this.padding,
    this.blurSigma = 25,
    this.scrollController,
  }) : assert(
          title != null || titleWidget != null,
          'Either title or titleWidget must be provided',
        );

  /// Returns the physical status bar height (including notch/dynamic island)
  /// from the window, independent of SafeArea consumption or edge-to-edge
  /// mode. Call from within screens to compute `topPadding` for scrollable
  /// content that needs to clear the header.
  static double statusBarHeight(BuildContext context) =>
      MediaQueryData.fromView(View.of(context)).viewPadding.top;

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  static const double _scrollBorderThreshold = 4.0;
  static const Duration _borderFadeDuration = Duration(milliseconds: 180);

  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant AppHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_onScroll);
      widget.scrollController?.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final controller = widget.scrollController;
    if (controller == null || !controller.hasClients) return;
    final shouldShow = controller.offset > _scrollBorderThreshold;
    if (shouldShow != _scrolled) {
      setState(() => _scrolled = shouldShow);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final bg = context.themeBackground;

    // Physical status bar height from the window. Use viewPadding (not
    // padding), because SystemUiMode.edgeToEdge collapses padding.top to 0
    // on Android while viewPadding still reports the real inset.
    final statusBarTop =
        MediaQueryData.fromView(View.of(context)).viewPadding.top;

    final effectivePadding = widget.padding ??
        EdgeInsets.fromLTRB(16, 12 + statusBarTop, 12, 12);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);

    final titleRow = Row(
      children: [
        if (widget.leading != null) ...[
          widget.leading!,
          const SizedBox(width: 12),
        ],
        Expanded(
          child: widget.titleWidget ??
              Text(
                widget.title!,
                style: TextStyle(
                  fontSize: widget.titleSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                  color: isDark
                      ? Colors.white
                      : AppColors.textLightPrimary,
                ),
              ),
        ),
        if (widget.actions != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: _withSpacing(widget.actions!, 8),
          ),
      ],
    );

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: widget.blurSigma,
          sigmaY: widget.blurSigma,
        ),
        child: AnimatedContainer(
          duration: _borderFadeDuration,
          padding: effectivePadding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      bg.withValues(alpha: 0.80),
                      bg.withValues(alpha: 0.60),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.85),
                      Colors.white.withValues(alpha: 0.65),
                    ],
            ),
            border: Border(
              bottom: BorderSide(
                color: _scrolled ? borderColor : Colors.transparent,
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 48, child: titleRow),
              if (widget.bottom != null) ...[
                const SizedBox(height: 10),
                widget.bottom!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  static List<Widget> _withSpacing(List<Widget> items, double gap) {
    if (items.length <= 1) return items;
    final result = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i < items.length - 1) result.add(SizedBox(width: gap));
    }
    return result;
  }
}
