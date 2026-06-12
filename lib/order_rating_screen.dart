import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'l10n/app_strings.dart';
import 'models/cart_item.dart';
import 'models/order.dart';
import 'models/ratings_manager.dart';
import 'models/auth_session.dart';
import 'services/api/api_exception.dart';
import 'services/api/order_ratings_service.dart';
import 'data/product_images.dart';
import 'services/product_line_enricher.dart';
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
  final OrderRatingsService _ratingsApi = OrderRatingsService();
  final ProductLineEnricher _enricher = ProductLineEnricher();
  final ImagePicker _picker = ImagePicker();

  double _storeStars = 0;
  final Map<String, double> _productStars = {};
  final Map<String, TextEditingController> _commentControllers = {};
  final Map<String, List<XFile>> _imageFiles = {};
  bool _submitting = false;
  bool _loading = true;

  bool get _storeAlreadyRated => _ratings.hasRatedStoreForOrder(widget.order.id);

  late Order _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _enrichOrderItems();
    if (_storeAlreadyRated) {
      _storeStars = _ratings.storeRatingForOrder(widget.order.id) ?? 0;
    }
    for (final item in _order.items) {
      _initProductRatingState(item.product.name);
    }
    if (mounted) setState(() => _loading = false);
  }

  void _initProductRatingState(String key) {
    if (_ratings.hasRatedProductForOrder(widget.order.id, key)) {
      final d = _ratings.productRatingDetail(widget.order.id, key);
      if (d != null) _productStars[key] = d.rating;
      return;
    }
    _commentControllers.putIfAbsent(key, TextEditingController.new);
    _imageFiles.putIfAbsent(key, () => <XFile>[]);
  }

  @override
  void dispose() {
    for (final c in _commentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<CartItem> get _pendingProducts => _order.items
      .where((e) => !_ratings.hasRatedProductForOrder(widget.order.id, e.product.name))
      .toList();

  Future<void> _enrichOrderItems() async {
    var storeId = widget.order.storeId;
    if (storeId == null && widget.order.storeName.trim().isNotEmpty) {
      storeId = await _enricher.resolveStoreId(widget.order.storeName);
    }
    final enriched = <CartItem>[];
    for (final line in widget.order.items) {
      enriched.add(
        await _enricher.enrichLine(
          line,
          storeId: storeId,
          storeName: widget.order.storeName,
        ),
      );
    }
    if (!mounted) return;
    setState(() => _order = widget.order.copyWith(items: enriched, storeId: storeId));
  }

  Future<void> _pickImages(String productKey) async {
    final file = await _picker.pickImage(imageQuality: 85, source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _imageFiles[productKey] = [file]);
  }

  bool get _canSubmit {
    if (_submitting) return false;
    final storeOk = _storeAlreadyRated || _storeStars >= 1;
    if (!storeOk) return false;
    if (_pendingProducts.isEmpty) return !_storeAlreadyRated;
    return _pendingProducts.every(
      (item) => (_productStars[item.product.name] ?? 0) >= 1,
    );
  }

  String _localizedOrRaw(BuildContext context, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    final translated = context.tr(trimmed);
    return translated == trimmed ? trimmed : translated;
  }

  Future<http.MultipartFile?> _multipartImage(String productKey) async {
    final xfiles = _imageFiles[productKey] ?? const [];
    if (xfiles.isEmpty) return null;
    final xfile = xfiles.first;
    final bytes = await xfile.readAsBytes();
    final name = xfile.name.isNotEmpty ? xfile.name : 'rating.jpg';
    return http.MultipartFile.fromBytes('image', bytes, filename: name);
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    if (!AuthSession.instance.isAuthenticated) {
      _showError(context.tr('login_required_for_rating'));
      return;
    }

    setState(() => _submitting = true);

    final storeNotFoundMsg = context.tr('rating_store_not_found');
    final productNotFoundMsg = context.tr('rating_product_not_found');

    try {
      // POST /api/stores/{storeId}/ratings — نجوم فقط
      if (!_storeAlreadyRated && _storeStars >= 1) {
        var storeId = _order.storeId;
        storeId ??= await _enricher.resolveStoreId(_order.storeName);
        if (storeId == null) {
          throw ApiException(storeNotFoundMsg);
        }
        await _ratingsApi.rateStore(storeId: storeId, stars: _storeStars.round());
        _ratings.submitStoreRating(
          orderId: widget.order.id,
          storeKey: _order.storeName,
          rating: _storeStars,
        );
      }

      // POST /api/products/{productId}/ratings — نجوم + رسالة + صورة
      for (final item in _pendingProducts) {
        final key = item.product.name;
        final stars = _productStars[key] ?? 0;
        if (stars < 1) continue;

        var productId = item.product.id ??
            await _enricher.resolveProductId(
              key,
              storeId: _order.storeId,
              storeName: _order.storeName,
            );
        if (productId == null) {
          throw ApiException('$productNotFoundMsg: $key');
        }

        final imageFile = await _multipartImage(key);
        final comment = _commentControllers[key]?.text;
        await _ratingsApi.rateProduct(
          productId: productId,
          stars: stars.round(),
          comment: comment,
          imageFile: imageFile,
        );
        _ratings.submitProductRating(
          orderId: widget.order.id,
          productKey: key,
          rating: stars,
          comment: comment,
          imagePaths: const [],
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('order_rated_done'), style: GoogleFonts.cairo()),
          backgroundColor: const Color(0xFF22C55E),
        ),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message, style: GoogleFonts.cairo()),
          backgroundColor: Colors.redAccent.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString(), style: GoogleFonts.cairo()),
          backgroundColor: Colors.redAccent.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: Colors.redAccent.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storeLabel = _localizedOrRaw(context, _order.storeName);
    final allDone = _ratings.isOrderFullyRated(
      widget.order.id,
      _order.items.map((e) => e.product.name).toList(),
    );

    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFF121026),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
        ),
      );
    }

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
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    context.tr('order_rating_title'),
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AppBackIconButton(),
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
                          'id': _order.id,
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
                    for (final item in _order.items) ...[
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
                    backgroundColor: const Color(0xFF2A2845),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF2A2845),
                    disabledForegroundColor: Colors.white38,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
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

  String _productImageUrl(CartItem item) {
    final remote = item.product.imageUrl.trim();
    if (remote.isNotEmpty) return remote;
    return ProductImages.forProductKey(item.product.name);
  }

  Widget _productRatingBlock(CartItem item) {
    final key = item.product.name;
    final already = _ratings.hasRatedProductForOrder(widget.order.id, key);
    final stars = _productStars[key] ?? 0;
    final colorSize = [
      if (item.selectedColor.trim().isNotEmpty) _localizedOrRaw(context, item.selectedColor),
      if (item.selectedSize.trim().isNotEmpty) item.selectedSize,
    ].join(' • ');

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: StoreCoverImage(
                  imageUrl: _productImageUrl(item),
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
                      _localizedOrRaw(context, key),
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (colorSize.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        colorSize,
                        style: GoogleFonts.cairo(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (already) ...[
            const SizedBox(height: 16),
            _starRow(stars, null),
            const SizedBox(height: 8),
            Text(
              context.tr('products_rated_done'),
              style: GoogleFonts.cairo(color: Colors.greenAccent, fontSize: 13),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Text(
              context.tr('product_stars_label'),
              style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            _starRow(stars, (v) => setState(() => _productStars[key] = v)),
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
            if (_imageFiles[key]?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    _RatingPhotoThumb(xfile: _imageFiles[key]!.first, size: 120),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: GestureDetector(
                        onTap: () => setState(() => _imageFiles[key] = []),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
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

class _RatingPhotoThumb extends StatelessWidget {
  const _RatingPhotoThumb({required this.xfile, this.size = 72});

  final XFile xfile;
  final double size;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: xfile.readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(width: size, height: size, child: const ColoredBox(color: Colors.white12));
        }
        return Image.memory(snapshot.data!, width: size, height: size, fit: BoxFit.cover);
      },
    );
  }
}
