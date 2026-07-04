import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/theme.dart';

/// A reusable cached network image widget with consistent styling.
/// Provides placeholder, error handling, and fade-in animation.
/// Supports both network URLs and local file paths.
class AppImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool highQuality;

  const AppImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.highQuality = false,
  });

  /// Check if the URL is a local file path
  bool get _isLocalFile {
    if (imageUrl == null || kIsWeb) return false;
    return imageUrl!.startsWith('/') || imageUrl!.startsWith('file://');
  }

  /// Normalize a network URL for the current platform.
  /// On web: route through wsrv.nl proxy (CORS workaround) with quality params.
  /// Everywhere: upgrade http:// to https:// to avoid mixed-content failures.
  String _normalizeNetworkUrl(String url) {
    var normalized = url.startsWith('http://')
        ? url.replaceFirst('http://', 'https://')
        : url;
    if (kIsWeb) {
      final params = highQuality ? '&w=400&q=90' : '&w=200&q=80';
      normalized =
          'https://wsrv.nl/?url=${Uri.encodeComponent(normalized)}$params';
    }
    return normalized;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    // If no URL, show placeholder immediately
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorWidget(isDark);
    }

    Widget image;

    // Handle local file paths (for backup restore)
    if (_isLocalFile) {
      final filePath = imageUrl!.startsWith('file://')
          ? imageUrl!.replaceFirst('file://', '')
          : imageUrl!;
      final file = File(filePath);

      image = FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          // Show placeholder while loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return placeholder ?? _buildPlaceholder(isDark);
          }
          // Show image if file exists
          if (snapshot.data == true) {
            return Image.file(
              file,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (context, error, stackTrace) =>
                  errorWidget ?? _buildErrorWidget(isDark),
            );
          }
          // File doesn't exist - show error widget
          return errorWidget ?? _buildErrorWidget(isDark);
        },
      );
    } else {
      // Network URL - use cached network image
      image = CachedNetworkImage(
        imageUrl: _normalizeNetworkUrl(imageUrl!),
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => placeholder ?? _buildPlaceholder(isDark),
        errorWidget: (context, url, error) =>
            errorWidget ?? _buildErrorWidget(isDark),
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 200),
      );
    }

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      width: width,
      height: height,
      color: isDark ? Colors.grey[800] : Colors.grey[200],
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: isDark ? Colors.white38 : Colors.black26,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(bool isDark) {
    return Container(
      width: width,
      height: height,
      color: isDark ? Colors.grey[800] : Colors.grey[100],
      child: Center(
        child: Icon(
          PhosphorIconsRegular.book,
          size: 32,
          color: isDark ? Colors.white24 : Colors.black26,
        ),
      ),
    );
  }
}

/// Specialized version for profile avatars with circular shape.
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 20,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildDefaultAvatar(isDark);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      imageBuilder: (context, imageProvider) =>
          CircleAvatar(radius: radius, backgroundImage: imageProvider),
      placeholder: (context, url) => placeholder ?? _buildLoadingAvatar(isDark),
      errorWidget: (context, url, error) =>
          errorWidget ?? _buildDefaultAvatar(isDark),
      fadeInDuration: const Duration(milliseconds: 200),
    );
  }

  Widget _buildLoadingAvatar(bool isDark) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
      child: SizedBox(
        width: radius,
        height: radius,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: isDark ? Colors.white38 : Colors.black26,
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(bool isDark) {
    return Builder(
      builder: (context) {
        final primaryColor = Theme.of(context).colorScheme.primary;
        return CircleAvatar(
          radius: radius,
          backgroundColor: primaryColor.withValues(alpha: isDark ? 0.3 : 0.1),
          child: Icon(
            PhosphorIconsRegular.user,
            size: radius,
            color: primaryColor,
          ),
        );
      },
    );
  }
}
