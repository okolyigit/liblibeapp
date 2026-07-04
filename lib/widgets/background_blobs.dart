import 'package:flutter/material.dart';
import '../theme/theme.dart';

class BackgroundBlobs extends StatefulWidget {
  const BackgroundBlobs({super.key});

  @override
  State<BackgroundBlobs> createState() => _BackgroundBlobsState();
}

class _BackgroundBlobsState extends State<BackgroundBlobs> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isBlack = context.isBlackTheme;

    final size = MediaQuery.of(context).size;
    final blobSize = size.width * 1.2;

    // Adjust opacity based on theme
    final double blob1Alpha;
    final double blob2Alpha;
    if (isBlack) {
      blob1Alpha = 0.08;
      blob2Alpha = 0.06;
    } else if (isDark) {
      blob1Alpha = 0.18;
      blob2Alpha = 0.15;
    } else {
      blob1Alpha = 0.10;
      blob2Alpha = 0.08;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final move1 = _controller.value * 20;
        final move2 = (1 - _controller.value) * 20;

        return Stack(
          children: [
            // Blob 1 (Top Left) - Primary Color (Emerald)
            Positioned(
              top: -blobSize * 0.2 + move1,
              left: -blobSize * 0.2 - move1,
              child: Container(
                width: blobSize,
                height: blobSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.emerald.withValues(alpha: blob1Alpha),
                      AppColors.emerald.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
            // Blob 2 (Bottom Right) - Secondary Color (Lime)
            Positioned(
              bottom: -blobSize * 0.1 + move2,
              right: -blobSize * 0.2 - move2,
              child: Container(
                width: blobSize * 0.8,
                height: blobSize * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.lime.withValues(alpha: blob2Alpha),
                      AppColors.lime.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
