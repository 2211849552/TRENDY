import '../models/product_view_angle.dart';
import 'product_color_images.dart';
import 'product_image_catalog.dart';

/// عنصر في معرض صور المنتج لكل لون.
class ProductGalleryItem {
  final ProductViewAngle angle;
  final String imageUrl;

  const ProductGalleryItem({
    required this.angle,
    required this.imageUrl,
  });
}

/// صور إضافية من الكتالوج لنفس عائلة اللون (زوايا مختلفة بصرياً).
class ProductGalleryData {
  ProductGalleryData._();

  static const _angles = [
    ProductViewAngle.front,
    ProductViewAngle.back,
    ProductViewAngle.upperDetail,
    ProductViewAngle.side,
    ProductViewAngle.lowerDetail,
    ProductViewAngle.fullBody,
  ];

  static List<ProductGalleryItem> galleryFor({
    required String productKey,
    required String colorKey,
    required String baseImageUrl,
  }) {
    final colorUrl = ProductColorImages.imageUrlFor(productKey, colorKey, baseImageUrl);
    if (ProductColorImages.hasDedicatedImages(productKey)) {
      return [
        ProductGalleryItem(angle: ProductViewAngle.front, imageUrl: colorUrl),
      ];
    }
    final extras = _colorRelatedImages(productKey, colorKey);
    return [
      ProductGalleryItem(angle: ProductViewAngle.front, imageUrl: colorUrl),
      ProductGalleryItem(
        angle: ProductViewAngle.back,
        imageUrl: extras.isNotEmpty ? extras[0] : baseImageUrl,
      ),
      ProductGalleryItem(angle: ProductViewAngle.upperDetail, imageUrl: baseImageUrl),
      ProductGalleryItem(
        angle: ProductViewAngle.side,
        imageUrl: extras.length > 1 ? extras[1] : baseImageUrl,
      ),
      ProductGalleryItem(
        angle: ProductViewAngle.lowerDetail,
        imageUrl: extras.length > 2 ? extras[2] : baseImageUrl,
      ),
      ProductGalleryItem(angle: ProductViewAngle.fullBody, imageUrl: baseImageUrl),
    ];
  }

  static List<ProductViewAngle> get allAngles => _angles;

  static List<String> _colorRelatedImages(String productKey, String colorKey) {
    final pool = _poolForColor(colorKey);
    final filtered = pool.where((k) => k != productKey).toList();
    if (filtered.isEmpty) return [];
    final start = productKey.hashCode.abs() % filtered.length;
    return [
      for (var i = 0; i < 3; i++)
        kProductImageCatalog[filtered[(start + i) % filtered.length]]!,
    ];
  }

  static List<String> _poolForColor(String colorKey) {
    final all = kProductImageCatalog.keys.toList();
    bool matches(String k) {
      switch (colorKey) {
        case 'white':
          return k.contains('white') ||
              k.contains('blouse') ||
              k.contains('shirt') ||
              k.contains('dress') ||
              k.contains('maxi');
        case 'navy':
          return k.contains('navy') || k.contains('blazer') || k.contains('oxford');
        case 'grey':
          return k.contains('grey') ||
              k.contains('sweat') ||
              k.contains('knit') ||
              k.contains('relaxed');
        case 'black':
        default:
          return k.contains('black') ||
              k.contains('wool') ||
              k.contains('formal') ||
              k.contains('denim') ||
              k.contains('evening');
      }
    }

    final matched = all.where(matches).toList();
    return matched.isNotEmpty ? matched : all;
  }
}
