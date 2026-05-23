import 'package:flutter/material.dart';
import 'product_color_images.dart';

/// تلوين منطقة المنتج (وسط الصورة) أو صور حقيقية لكل لون عند توفرها.
class ProductColorVariants {
  ProductColorVariants._();

  static const availableColors = ['black', 'white', 'navy', 'grey'];

  static List<String> colorsFor(String productKey) {
    return ProductColorImages.colorsFor(productKey);
  }

  static String defaultColorFor(String productKey) {
    if (ProductColorImages.hasDedicatedImages(productKey)) {
      return ProductColorImages.defaultColorFor(productKey);
    }
    final k = productKey.toLowerCase();
    if (k.contains('white')) return 'white';
    if (k.contains('navy')) return 'navy';
    if (k.contains('black')) return 'black';
    return 'black';
  }

  static bool usesDedicatedPhoto(String productKey, String colorKey) {
    return ProductColorImages.imageFor(productKey, colorKey) != null;
  }

  static bool showsOriginalPhoto(String productKey, String colorKey) {
    if (usesDedicatedPhoto(productKey, colorKey)) return true;
    return colorKey == defaultColorFor(productKey);
  }

  static Color displayColor(String colorKey) {
    return ProductColorImages.displayColor(colorKey);
  }

  static ColorFilter? productTintFilter(String productKey, String colorKey) {
    if (usesDedicatedPhoto(productKey, colorKey)) return null;
    if (showsOriginalPhoto(productKey, colorKey)) return null;
    return _tintFor(colorKey);
  }

  static ColorFilter? _tintFor(String colorKey) {
    switch (colorKey) {
      case 'white':
        return ColorFilter.mode(
          Colors.white.withValues(alpha: 0.42),
          BlendMode.screen,
        );
      case 'black':
        return ColorFilter.mode(
          Colors.black.withValues(alpha: 0.48),
          BlendMode.multiply,
        );
      case 'navy':
        return ColorFilter.mode(
          const Color(0xFF1E3A5F).withValues(alpha: 0.5),
          BlendMode.color,
        );
      case 'grey':
        return ColorFilter.mode(
          const Color(0xFF888888).withValues(alpha: 0.45),
          BlendMode.color,
        );
      default:
        return null;
    }
  }

  static Shader productMaskShader(Rect bounds) {
    return RadialGradient(
      center: const Alignment(0, 0.08),
      radius: 0.78,
      colors: [
        Colors.white,
        Colors.white.withValues(alpha: 0.92),
        Colors.white.withValues(alpha: 0.35),
        Colors.transparent,
      ],
      stops: const [0.0, 0.42, 0.68, 1.0],
    ).createShader(bounds);
  }
}
