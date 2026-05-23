import 'package:flutter/material.dart';

/// يعرض صورة غلاف المتجر من ملف محلي ([assets/...]) أو من رابط شبكة.
class StoreCoverImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  const StoreCoverImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  static bool isAssetPath(String url) => url.startsWith('assets/');

  static ImageProvider imageProvider(String url) {
    if (isAssetPath(url)) return AssetImage(url);
    return NetworkImage(url);
  }

  @override
  Widget build(BuildContext context) {
    final Widget image;
    if (isAssetPath(imageUrl)) {
      image = Image.asset(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: _errorBuilder,
      );
    } else {
      image = Image.network(
        imageUrl,
        fit: fit,
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

    if (width != null || height != null) return image;
    return SizedBox.expand(child: image);
  }

  Widget _errorBuilder(BuildContext context, Object error, StackTrace? stackTrace) {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: const Center(
        child: Icon(Icons.checkroom_outlined, color: Color(0xFF94A3B8), size: 40),
      ),
    );
  }
}
