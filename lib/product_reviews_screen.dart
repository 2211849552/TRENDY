import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'l10n/app_strings.dart';
import 'models/cart_item.dart';
import 'models/customer_review.dart';
import 'models/ratings_manager.dart';
import 'widgets/app_back_button.dart';
import 'widgets/store_cover_image.dart';

/// عرض تعليقات وصور توضيحية من زبائن قيّموا المنتج.
class ProductReviewsScreen extends StatelessWidget {
  final String productKey;
  final String productImageUrl;
  final String? variantLabel;

  const ProductReviewsScreen({
    super.key,
    required this.productKey,
    required this.productImageUrl,
    this.variantLabel,
  });

  factory ProductReviewsScreen.fromCartItem(CartItem item, BuildContext context) {
    return ProductReviewsScreen(
      productKey: item.product.name,
      productImageUrl: item.product.imageUrl,
      variantLabel: '${context.tr(item.selectedColor)} · ${item.selectedSize}',
    );
  }

  List<String> _collectPhotoPaths(List<CustomerReview> reviews) {
    final paths = <String>[productImageUrl];
    for (final r in reviews) {
      if (r.imageAssetPath != null && !paths.contains(r.imageAssetPath)) {
        paths.add(r.imageAssetPath!);
      }
    }
    return paths;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RatingsManager(),
      builder: (context, _) {
        final reviews = RatingsManager().reviewsForProduct(productKey);
        final photos = _collectPhotoPaths(reviews);
        final avgRating = reviews.isEmpty
            ? 0.0
            : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;

        return Scaffold(
          backgroundColor: const Color(0xFF121026),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      const AppBackIconButton(),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.tr('customer_reviews_title'),
                          style: GoogleFonts.cairo(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: reviews.isEmpty
                      ? _buildEmpty(context)
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          children: [
                            _buildProductHeader(context, reviews.length, avgRating),
                            const SizedBox(height: 20),
                            _sectionLabel(context.tr('customer_photos_section')),
                            const SizedBox(height: 10),
                            _PhotoGallery(paths: photos),
                            const SizedBox(height: 24),
                            _sectionLabel(context.tr('customer_ratings_section')),
                            const SizedBox(height: 12),
                            ...reviews.map((r) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _ReviewCard(review: r),
                                )),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: StoreCoverImage(
                imageUrl: productImageUrl,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr(productKey),
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('no_reviews_yet'),
              style: GoogleFonts.cairo(color: Colors.white54, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductHeader(BuildContext context, int count, double avgRating) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: StoreCoverImage(
              imageUrl: productImageUrl,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(productKey),
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (variantLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    variantLabel!,
                    style: GoogleFonts.cairo(color: Colors.white54, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Stars(rating: avgRating.roundToDouble().clamp(1, 5)),
                    const SizedBox(width: 8),
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: GoogleFonts.cairo(color: Colors.amber, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppStrings.format(context, 'reviews_count_label', params: {
                        'count': count.toString(),
                      }),
                      style: GoogleFonts.cairo(color: const Color(0xFF3B82F6), fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.cairo(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _PhotoGallery extends StatelessWidget {
  final List<String> paths;

  const _PhotoGallery({required this.paths});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: paths.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _GalleryImage(path: paths[i]),
        ),
      ),
    );
  }
}

class _GalleryImage extends StatelessWidget {
  final String path;

  const _GalleryImage({required this.path});

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('assets/') || path.startsWith('http')) {
      return StoreCoverImage(imageUrl: path, width: 100, height: 100, fit: BoxFit.cover);
    }
    if (kIsWeb) {
      return Container(
        width: 100,
        height: 100,
        color: const Color(0xFF1E1B4B),
        child: const Icon(Icons.image_outlined, color: Colors.white38),
      );
    }
    return Image.file(File(path), width: 100, height: 100, fit: BoxFit.cover);
  }
}

class _ReviewCard extends StatelessWidget {
  final CustomerReview review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.authorName,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              _Stars(rating: review.rating),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14, height: 1.5),
            ),
          ],
          if (review.imageAssetPath != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _GalleryImage(path: review.imageAssetPath!),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final double rating;

  const _Stars({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final star = i + 1;
        return Icon(
          rating >= star ? Icons.star_rounded : Icons.star_border_rounded,
          color: Colors.amber,
          size: 18,
        );
      }),
    );
  }
}
