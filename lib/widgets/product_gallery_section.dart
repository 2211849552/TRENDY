import 'package:flutter/material.dart';

import '../data/product_images.dart';
import '../theme/trendy_theme_extension.dart';
import 'product_image_viewer.dart';
import 'store_cover_image.dart';

/// صورة المنتج الرئيسية — ثابتة ولا تتغير عند اختيار اللون.
class ProductGallerySection extends StatelessWidget {
  final String imageUrl;
  final String productKey;
  final String? storeName;

  const ProductGallerySection({
    super.key,
    required this.imageUrl,
    required this.productKey,
    this.storeName,
  });

  @override
  Widget build(BuildContext context) {
    final showFull = ProductImages.showsFullPhoto(productKey, storeName: storeName);
    final fit = ProductImages.photoFit(productKey, storeName: storeName);
    final imageHeight = MediaQuery.sizeOf(context).height * (showFull ? 0.52 : 0.42);
    final photoBg = showFull ? context.trendy.inputFill : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => ProductImageViewer.show(context, imageUrl: imageUrl),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: imageHeight,
            width: double.infinity,
            color: photoBg,
            alignment: Alignment.center,
            child: Stack(
              fit: StackFit.expand,
              children: [
                StoreCoverImage(
                  imageUrl: imageUrl,
                  fit: fit,
                  width: double.infinity,
                  height: imageHeight,
                ),
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.zoom_out_map, color: Colors.white70, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
