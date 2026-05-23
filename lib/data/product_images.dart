import 'package:flutter/material.dart';

import 'product_image_catalog.dart';

/// صور منتجات — كل منتج له رابط فريد من [kProductImageCatalog].
class ProductImages {
  ProductImages._();

  static String forProductKey(String productKey) {
    return kProductImageCatalog[productKey] ??
        'assets/images/products/prod_basic_tshirt.jpg';
  }

  /// صور تُعرض كاملة في صفحة التفاصيل (بدون قص)، بينما الشبكة تبقى cover.
  static bool showsFullPhoto(String productKey, {String? storeName}) {
    if (productKey.startsWith('prod_gentle_')) return true;
    if (storeName == 'store_elegance' ||
        storeName == 'store_luxury' ||
        storeName == 'store_kids') {
      return true;
    }
    return false;
  }

  static BoxFit photoFit(String productKey, {String? storeName}) =>
      showsFullPhoto(productKey, storeName: storeName) ? BoxFit.contain : BoxFit.cover;
}
