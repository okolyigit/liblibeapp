import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/theme.dart';

class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const AppBackButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Semantics(
      button: true,
      label: 'Geri',
      child: GestureDetector(
        onTap:
            onPressed ??
            () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.subtleTint,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          ),
          child: Center(
            child: Icon(
              PhosphorIconsRegular.arrowLeft,
              size: 20,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}
