import 'package:flutter/material.dart';

/// يعرض صورة المتجر من ملف محلي ([assets/...]) أو من رابط شبكة (شعار من API).
class StoreCoverImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  /// عرض الشعار دائرياً (من حقل `logo` في API) بدل صورة الغلاف.
  final bool asLogo;

  const StoreCoverImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.asLogo = false,
  });

  static bool isAssetPath(String url) => url.startsWith('assets/');

  static bool isRemoteUrl(String url) {
    final trimmed = url.trim();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  static bool hasDisplayableUrl(String url) => url.trim().isNotEmpty;

  static ImageProvider? imageProvider(String url) {
    if (!hasDisplayableUrl(url)) return null;
    if (isAssetPath(url)) return AssetImage(url);
    return NetworkImage(url);
  }

  @override
  Widget build(BuildContext context) {
    if (!hasDisplayableUrl(imageUrl)) {
      return _placeholder();
    }

    final effectiveFit = asLogo ? BoxFit.contain : fit;
    final Widget image;
    if (isAssetPath(imageUrl)) {
      image = Image.asset(
        imageUrl,
        fit: effectiveFit,
        width: width,
        height: height,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: _errorBuilder,
      );
    } else {
      image = Image.network(
        imageUrl,
        fit: effectiveFit,
        width: width,
        height: height,
        gaplessPlayback: true,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              color: const Color(0xFF3B82F6),
            ),
          );
        },
        errorBuilder: _errorBuilder,
      );
    }

    Widget result = image;
    if (asLogo) {
      final logoSize = width ?? height ?? 88.0;
      result = ClipOval(
        child: Container(
          width: logoSize,
          height: logoSize,
          color: const Color(0xFF1E1B2E),
          padding: const EdgeInsets.all(8),
          child: image,
        ),
      );
    } else if (width != null || height != null) {
      return image;
    } else {
      return SizedBox.expand(child: image);
    }

    return result;
  }

  Widget _placeholder() {
    final iconSize = asLogo ? 36.0 : 40.0;
    final child = Icon(Icons.storefront_outlined, color: const Color(0xFF94A3B8), size: iconSize);
    if (asLogo) {
      final logoSize = width ?? height ?? 88.0;
      return ClipOval(
        child: Container(
          width: logoSize,
          height: logoSize,
          color: const Color(0xFF1E1B2E),
          child: Center(child: child),
        ),
      );
    }
    return Container(
      color: const Color(0xFFF3F4F6),
      width: width,
      height: height,
      child: Center(child: child),
    );
  }

  Widget _errorBuilder(BuildContext context, Object error, StackTrace? stackTrace) {
    return _placeholder();
  }
}
