import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'l10n/app_strings.dart';
import 'models/cart_item.dart';
import 'models/order.dart';
import 'models/ratings_manager.dart';
import 'widgets/app_back_button.dart';
import 'widgets/store_cover_image.dart';

/// تقييم موحّد: المتجر (نجوم فقط) ثم المنتجات (نجوم + صور + تعليق).
class OrderRatingScreen extends StatefulWidget {
  final Order order;

  const OrderRatingScreen({super.key, required this.order});

  @override
  State<OrderRatingScreen> createState() => _OrderRatingScreenState();
}

class _OrderRatingScreenState extends State<OrderRatingScreen> {
  final RatingsManager _ratings = RatingsManager();
  final ImagePicker _picker = ImagePicker();

  double _storeStars = 0;
  final Map<String, double> _productStars = {};
  final Map<String, TextEditingController> _commentControllers = {};
  final Map<String, List<String>> _imagePaths = {};

  bool get _storeAlreadyRated => _ratings.hasRatedStoreForOrder(widget.order.id);

  @override
  void initState() {
    super.initState();
    if (_storeAlreadyRated) {
      _storeStars = _ratings.storeRatingForOrder(widget.order.id) ?? 0;
    }
    for (final item in widget.order.items) {
      final key = item.product.name;
      if (_ratings.hasRatedProductForOrder(widget.order.id, key)) {
        final d = _ratings.productRatingDetail(widget.order.id, key);
        if (d != null) _productStars[key] = d.rating;
      } else {
        _commentControllers[key] = TextEditingController();
        _imagePaths[key] = [];
      }
    }
  }

  @override
  void dispose() {
    for (final c in _commentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<CartItem> get _pendingProducts => widget.order.items
      .where((e) => !_ratings.hasRatedProductForOrder(widget.order.id, e.product.name))
      .toList();

  Future<void> _pickImages(String productKey) async {
    final files = await _picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;
    setState(() {
      _imagePaths.putIfAbsent(productKey, () => []);
      _imagePaths[productKey]!.addAll(files.map((f) => f.path));
    });
  }

  bool get _canSubmit {
    if (_pendingProducts.isEmpty) {
      return !_storeAlreadyRated && _storeStars >= 1;
    }
    return _pendingProducts.every(
      (item) => (_productStars[item.product.name] ?? 0) >= 1,
    );
  }

  double _effectiveStoreRating() {
    if (_storeAlreadyRated) {
      return _ratings.storeRatingForOrder(widget.order.id) ?? _storeStars;
    }
    if (_storeStars >= 1) return _storeStars;
    final productRatings = _pendingProducts
        .map((e) => _productStars[e.product.name] ?? 0)
        .where((s) => s >= 1)
        .toList();
    if (productRatings.isEmpty) return 0;
    return productRatings.reduce((a, b) => a + b) / productRatings.length;
  }

  void _submit() {
    if (!_storeAlreadyRated) {
      final storeRating = _effectiveStoreRating();
      if (storeRating >= 1) {
        _ratings.submitStoreRating(
          orderId: widget.order.id,
          storeKey: widget.order.storeName,
          rating: storeRating,
        );
      }
    }
    for (final item in _pendingProducts) {
      final key = item.product.name;
      final stars = _productStars[key] ?? 0;
      if (stars < 1) continue;
      _ratings.submitProductRating(
        orderId: widget.order.id,
        productKey: key,
        rating: stars,
        comment: _commentControllers[key]?.text,
        imagePaths: _imagePaths[key] ?? const [],
      );
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final storeLabel = context.tr(widget.order.storeName);
    final allDone = _ratings.isOrderFullyRated(
      widget.order.id,
      widget.order.items.map((e) => e.product.name).toList(),
    );

    if (allDone) {
      return Scaffold(
        backgroundColor: const Color(0xFF121026),
        body: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(8),
                child: Align(alignment: AlignmentDirectional.centerStart, child: AppBackIconButton()),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    context.tr('order_rated_done'),
                    style: GoogleFonts.cairo(color: Colors.white70, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121026),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  const AppBackIconButton(),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('order_rating_title'),
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _card(
                      child: Text(
                        AppStrings.format(context, 'order_rating_order_line', params: {
                          'id': widget.order.id,
                          'store': storeLabel,
                        }),
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle(Icons.storefront_outlined, context.tr('store_rating_section')),
                          const SizedBox(height: 12),
                          Text(
                            AppStrings.format(context, 'store_rating_prompt', params: {'store': storeLabel}),
                            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 15),
                          ),
                          const SizedBox(height: 16),
                          _starRow(
                            _storeStars,
                            _storeAlreadyRated ? null : (v) => setState(() => _storeStars = v),
                          ),
                          if (_storeAlreadyRated)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                context.tr('store_rated_done'),
                                style: GoogleFonts.cairo(color: Colors.greenAccent, fontSize: 13),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _sectionTitle(Icons.inventory_2_outlined, context.tr('product_rating_section')),
                    const SizedBox(height: 12),
                    for (final item in widget.order.items) ...[
                      _productRatingBlock(item),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA855F7),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white12,
                    disabledForegroundColor: Colors.white38,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    context.tr('submit_rating'),
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productRatingBlock(CartItem item) {
    final key = item.product.name;
    final already = _ratings.hasRatedProductForOrder(widget.order.id, key);
    final stars = _productStars[key] ?? 0;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: StoreCoverImage(
                  imageUrl: item.product.imageUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(key),
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${context.tr(item.selectedColor)} · ${item.selectedSize}',
                      style: GoogleFonts.cairo(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _starRow(stars, already ? null : (v) => setState(() => _productStars[key] = v)),
          if (already) ...[
            const SizedBox(height: 8),
            Text(
              context.tr('products_rated_done'),
              style: GoogleFonts.cairo(color: Colors.greenAccent, fontSize: 13),
            ),
          ] else ...[
            const SizedBox(height: 20),
            Text(
              context.tr('rating_attach_photos'),
              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _pickImages(key),
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(context.tr('rating_choose_photos'), style: GoogleFonts.cairo()),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF3B82F6),
                side: const BorderSide(color: Color(0xFF3B82F6)),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.format(context, 'rating_photos_count', params: {
                'count': (_imagePaths[key]?.length ?? 0).toString(),
              }),
              style: GoogleFonts.cairo(color: Colors.white54, fontSize: 13),
            ),
            if (_imagePaths[key]?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imagePaths[key]!.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final path = _imagePaths[key]![i];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: kIsWeb
                              ? const SizedBox(width: 72, height: 72)
                              : Image.file(File(path), width: 72, height: 72, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 2,
                          left: 2,
                          child: GestureDetector(
                            onTap: () => setState(() => _imagePaths[key]!.removeAt(i)),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              context.tr('rating_extra_notes'),
              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentControllers[key],
              maxLines: 3,
              style: GoogleFonts.cairo(color: Colors.white),
              decoration: InputDecoration(
                hintText: context.tr('rating_comment_hint'),
                hintStyle: GoogleFonts.cairo(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF121026),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF3B82F6), size: 22),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }

  Widget _starRow(double value, ValueChanged<double>? onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final star = (i + 1).toDouble();
        return IconButton(
          onPressed: onChanged == null ? null : () => onChanged(star),
          icon: Icon(
            value >= star ? Icons.star_rounded : Icons.star_border_rounded,
            color: Colors.amber,
            size: 36,
          ),
        );
      }),
    );
  }
}
