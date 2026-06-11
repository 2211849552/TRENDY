import 'package:flutter/material.dart';

import 'customer_reviews_screen.dart';
import 'l10n/app_strings.dart';
import 'models/cart_item.dart';

export 'customer_reviews_screen.dart' show CustomerReviewsScreen, ReviewScope;

/// غلاف للتوافق — يستخدم [CustomerReviewsScreen] مع API التقييمات.
class ProductReviewsScreen extends CustomerReviewsScreen {
  ProductReviewsScreen({
    required String productKey,
    required String productImageUrl,
    String? variantLabel,
    int? productId,
    super.key,
  }) : super(
          scope: ReviewScope.product,
          entityId: productId,
          title: productKey,
          imageUrl: productImageUrl,
          subtitle: variantLabel,
        );

  factory ProductReviewsScreen.fromCartItem(CartItem item, BuildContext context) {
    return ProductReviewsScreen(
      productKey: item.product.name,
      productImageUrl: item.product.imageUrl,
      variantLabel: '${context.tr(item.selectedColor)} · ${item.selectedSize}',
      productId: item.product.id,
    );
  }
}
