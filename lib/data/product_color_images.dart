import 'package:flutter/material.dart';

/// صور حقيقية لكل لون — عند توفرها تُعرض بدل التلوين الاصطناعي.
class ProductColorImages {
  ProductColorImages._();

  static const _poloKnit = 'prod_polo_knit';

  static const Map<String, Map<String, String>> _byProduct = {
    _poloKnit: {
      'green': 'assets/images/products/prod_polo_knit_green.png',
      'brown': 'assets/images/products/prod_polo_knit_brown.png',
      'burgundy': 'assets/images/products/prod_polo_knit_burgundy.png',
      'teal': 'assets/images/products/prod_polo_knit_teal.png',
    },
  };

  static const Map<String, List<String>> _colorsByProduct = {
    _poloKnit: ['green', 'brown', 'burgundy', 'teal'],
  };

  static List<String> colorsFor(String productKey) {
    return _colorsByProduct[productKey] ?? const ['black', 'white', 'navy', 'grey'];
  }

  static bool hasDedicatedImages(String productKey) {
    return _byProduct.containsKey(productKey);
  }

  static String? imageFor(String productKey, String colorKey) {
    return _byProduct[productKey]?[colorKey];
  }

  static String imageUrlFor(String productKey, String colorKey, String fallback) {
    return imageFor(productKey, colorKey) ?? fallback;
  }

  static String defaultColorFor(String productKey) {
    if (productKey == _poloKnit) return 'green';
    return 'black';
  }

  static Color displayColor(String colorKey) {
    switch (colorKey) {
      case 'green':
        return const Color(0xFF2D5A3D);
      case 'brown':
        return const Color(0xFF5C3D2E);
      case 'burgundy':
        return const Color(0xFF6B2D3C);
      case 'teal':
        return const Color(0xFF1F5C5C);
      case 'white':
        return const Color(0xFFF5F5F5);
      case 'navy':
        return const Color(0xFF1B2A4A);
      case 'grey':
        return const Color(0xFF757575);
      case 'black':
      default:
        return const Color(0xFF1A1A1A);
    }
  }
}
