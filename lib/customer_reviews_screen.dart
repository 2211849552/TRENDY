import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'l10n/app_strings.dart';
import 'models/cart_item.dart';
import 'models/customer_review.dart';
import 'models/product.dart';
import 'models/ratings_manager.dart';
import 'services/api/api_exception.dart';
import 'services/api/ratings_api.dart';
import 'widgets/app_back_button.dart';
import 'widgets/store_cover_image.dart';

enum ReviewScope { product }

/// عرض تعليقات وتقييمات الزبائن على المنتج من API.
class CustomerReviewsScreen extends StatefulWidget {
  final ReviewScope scope;
  final int? entityId;
  final String title;
  final String imageUrl;
  final String? subtitle;

  const CustomerReviewsScreen({
    super.key,
    required this.scope,
    this.entityId,
    required this.title,
    required this.imageUrl,
    this.subtitle,
  });

  factory CustomerReviewsScreen.product({
    required Product product,
    String? variantLabel,
  }) {
    return CustomerReviewsScreen(
      scope: ReviewScope.product,
      entityId: product.id,
      title: product.name,
      imageUrl: product.imageUrl,
      subtitle: variantLabel,
    );
  }

  factory CustomerReviewsScreen.fromCartItem(CartItem item, BuildContext context) {
    return CustomerReviewsScreen.product(
      product: item.product,
      variantLabel: '${context.tr(item.selectedColor)} · ${item.selectedSize}',
    );
  }

  @override
  State<CustomerReviewsScreen> createState() => _CustomerReviewsScreenState();
}

class _CustomerReviewsScreenState extends State<CustomerReviewsScreen> {
  final RatingsApi _ratingsApi = RatingsApi();
  final List<CustomerReview> _reviews = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _lastPage = 1;
  double _averageRating = 0;
  int _totalRatings = 0;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({required bool reset}) async {
    final id = widget.entityId;
    if (id == null || id <= 0) {
      _loadLocalOnly();
      return;
    }

    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final result = await _ratingsApi.fetchProductRatings(id, page: reset ? 1 : _page + 1);

      if (!mounted) return;
      setState(() {
        if (reset) {
          _reviews
            ..clear()
            ..addAll(result.ratings.map((r) => r.toCustomerReview()));
        } else {
          _reviews.addAll(result.ratings.map((r) => r.toCustomerReview()));
        }
        _averageRating = result.averageRating;
        _totalRatings = result.totalRatings;
        _page = result.currentPage;
        _lastPage = result.lastPage;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (reset && _reviews.isEmpty) _loadLocalOnly(fallbackError: e.message);
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      if (reset && _reviews.isEmpty) _loadLocalOnly(fallbackError: e.toString());
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  void _loadLocalOnly({String? fallbackError}) {
    final local = RatingsManager().reviewsForProduct(widget.title);
    setState(() {
      _reviews
        ..clear()
        ..addAll(local);
      _averageRating = local.isEmpty
          ? 0
          : local.map((r) => r.rating).reduce((a, b) => a + b) / local.length;
      _totalRatings = local.length;
      _error = local.isEmpty ? fallbackError : null;
      _loading = false;
      _loadingMore = false;
      _lastPage = 1;
    });
  }

  List<String> _collectPhotoPaths(List<CustomerReview> reviews) {
    final paths = <String>[];
    if (widget.imageUrl.trim().isNotEmpty) paths.add(widget.imageUrl);
    for (final review in reviews) {
      for (final url in review.imageUrls) {
        if (!paths.contains(url)) paths.add(url);
      }
      final legacy = review.imageAssetPath;
      if (legacy != null && legacy.isNotEmpty && !paths.contains(legacy)) {
        paths.add(legacy);
      }
    }
    return paths;
  }

  @override
  Widget build(BuildContext context) {
    final reviews = _reviews;
    final photos = _collectPhotoPaths(reviews);
    final avgRating = _averageRating > 0
        ? _averageRating
        : reviews.isEmpty
            ? 0.0
            : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
    final count = _totalRatings > 0 ? _totalRatings : reviews.length;

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
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (reviews.isEmpty)
              Expanded(child: _buildEmpty(context))
            else
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (_loadingMore || _page >= _lastPage) return false;
                    if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 120) {
                      _load(reset: false);
                    }
                    return false;
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                      _buildHeader(context, count, avgRating),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: GoogleFonts.cairo(color: Colors.orangeAccent, fontSize: 13),
                        ),
                      ],
                      if (photos.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _sectionLabel(context.tr('customer_photos_section')),
                        const SizedBox(height: 10),
                        _PhotoGallery(paths: photos),
                      ],
                      const SizedBox(height: 24),
                      _sectionLabel(context.tr('customer_ratings_section')),
                      const SizedBox(height: 12),
                      ...reviews.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ReviewCard(review: r),
                        ),
                      ),
                      if (_loadingMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.imageUrl.trim().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: StoreCoverImage(
                  imageUrl: widget.imageUrl,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              context.tr(widget.title),
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? context.tr('no_reviews_yet'),
              style: GoogleFonts.cairo(color: Colors.white54, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count, double avgRating) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          if (widget.imageUrl.trim().isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: StoreCoverImage(
                imageUrl: widget.imageUrl,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
              ),
            ),
          if (widget.imageUrl.trim().isNotEmpty) const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(widget.title),
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle!,
                    style: GoogleFonts.cairo(color: Colors.white54, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Stars(rating: avgRating.roundToDouble().clamp(0, 5)),
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
    final images = review.imageUrls.isNotEmpty
        ? review.imageUrls
        : (review.imageAssetPath != null ? [review.imageAssetPath!] : const <String>[]);

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
          if (images.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: images.map((path) => _GalleryImage(path: path)).toList(),
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
