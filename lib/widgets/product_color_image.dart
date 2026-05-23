import 'package:flutter/material.dart';
import '../data/product_color_images.dart';
import '../data/product_color_variants.dart';
import 'store_cover_image.dart';

/// نفس صورة المنتج — التلوين على القطعة في الوسط فقط وليس الخلفية.
class ProductColorImage extends StatelessWidget {
  final String productKey;
  final String colorKey;
  final String baseImageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ProductColorImage({
    super.key,
    required this.productKey,
    required this.colorKey,
    required this.baseImageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final dedicatedUrl = ProductColorImages.imageFor(productKey, colorKey);
    if (dedicatedUrl != null) {
      Widget content = StoreCoverImage(
        imageUrl: dedicatedUrl,
        fit: fit,
        width: width,
        height: height,
      );
      if (borderRadius != null) {
        content = ClipRRect(borderRadius: borderRadius!, child: content);
      }
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey<String>('$productKey-$colorKey-$dedicatedUrl'),
          child: content,
        ),
      );
    }

    final showOriginal = ProductColorVariants.showsOriginalPhoto(productKey, colorKey);
    final tintFilter = ProductColorVariants.productTintFilter(productKey, colorKey);

    Widget content = _buildImageStack(showOriginal: showOriginal, tintFilter: tintFilter);

    if (borderRadius != null) {
      content = ClipRRect(borderRadius: borderRadius!, child: content);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(
        key: ValueKey<String>('$productKey-$colorKey-$baseImageUrl'),
        child: content,
      ),
    );
  }

  Widget _buildImageStack({required bool showOriginal, ColorFilter? tintFilter}) {
    final base = StoreCoverImage(
      imageUrl: baseImageUrl,
      fit: fit,
      width: width,
      height: height,
    );

    if (showOriginal || tintFilter == null) {
      return base;
    }

    Widget tinted = StoreCoverImage(
      imageUrl: baseImageUrl,
      fit: fit,
      width: width,
      height: height,
    );
    tinted = ColorFiltered(colorFilter: tintFilter, child: tinted);

    return Stack(
      fit: StackFit.passthrough,
      alignment: Alignment.center,
      children: [
        base,
        ShaderMask(
          shaderCallback: ProductColorVariants.productMaskShader,
          blendMode: BlendMode.dstIn,
          child: tinted,
        ),
      ],
    );
  }
}
