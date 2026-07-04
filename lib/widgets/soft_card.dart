import 'package:flutter/material.dart';

class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double? height;
  final double? width;
  final Color? color;
  final Border? border;

  const SoftCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.height,
    this.width,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color ?? Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(32),
          border: border,
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 6),
              blurRadius: 20,
              color: Color.fromRGBO(0, 0, 0, 0.06),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
