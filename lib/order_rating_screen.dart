import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'l10n/app_strings.dart';
import 'models/cart_item.dart';
import 'models/order.dart';
import 'models/ratings_manager.dart';
import 'models/auth_session.dart';
import 'services/api/api_exception.dart';
import 'services/api/order_ratings_service.dart';
import 'services/api/orders_api.dart';
import 'services/api/ratings_api.dart';
import 'data/product_images.dart';
import 'services/product_line_enricher.dart';
import 'utils/rating_ownership.dart';
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
  final RatingsApi _listRatingsApi = RatingsApi();
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
    await _ratings.ensureLoaded();
    await _loadOrderWithItems();
    await _enrichOrderItems();
    await _syncExistingRatingsFromApi();
    if (_storeAlreadyRated) {
      _storeStars = _ratings.storeRatingForOrder(widget.order.id) ?? 0;
    }
    for (final item in _order.items) {
      _initProductRatingState(item.product.name);
    }
    if (mounted) setState(() => _loading = false);
  }

  /// GET /api/orders/{id} — قائمة الطلبات لا تتضمن المنتجات دائماً.
  Future<void> _loadOrderWithItems() async {
    final apiId = _order.apiId;
    if (apiId != null && apiId > 0) {
      try {
        final fresh = await OrdersApi().fetchOrderDetails(apiId);
        if (fresh != null) {
          _order = fresh;
        }
      } on ApiException {
        // نعتمد على بيانات الطلب المُمرَّرة أو التخزين المحلي
      }
    }
    if (_order.items.isEmpty && widget.order.items.isNotEmpty) {
      _order = _order.copyWith(items: widget.order.items);
    }
  }

  /// يطابق تقييمات السيرver — التطبيق يحفظها محلياً في الذاكرة فقط.
  Future<void> _syncExistingRatingsFromApi() async {
    if (!AuthSession.instance.isAuthenticated) return;

    var storeId = _order.storeId;
    storeId ??= await _enricher.resolveStoreId(_order.storeName);

    if (storeId != null && !_storeAlreadyRated) {
      try {
        final page = await _listRatingsApi.fetchStoreRatings(storeId, perPage: 50);
        for (final rating in page.ratings) {
          if (!ratingBelongsToCurrentUser(
            authorName: rating.authorName,
            authorId: rating.authorId,
          )) continue;
          _ratings.submitStoreRating(
            orderId: widget.order.id,
            storeKey: _order.storeName,
            rating: rating.stars.toDouble(),
          );
          break;
        }
      } on ApiException {
        // تجاهل — الإرسال سيُعالج التكرار لاحقاً
      }
    }

    for (final item in _order.items) {
      final key = item.product.name;
      if (_ratings.hasRatedProductForOrder(widget.order.id, key)) continue;
      final productId = item.product.id;
      if (productId == null) continue;
      try {
        final page = await _listRatingsApi.fetchProductRatings(productId, perPage: 50);
        for (final rating in page.ratings) {
          if (!ratingBelongsToCurrentUser(
            authorName: rating.authorName,
            authorId: rating.authorId,
          )) continue;
          _ratings.submitProductRating(
            orderId: widget.order.id,
            productKey: key,
            rating: rating.stars.toDouble(),
            comment: rating.comment.isNotEmpty ? rating.comment : null,
          );
          break;
        }
      } on ApiException {
        // تجاهل
      }
    }
  }

  bool _isStoreDuplicateError(ApiException e) =>
      e.statusCode == 403 && e.message.contains('مرة');

  bool _isProductDuplicateError(ApiException e) =>
      e.statusCode == 403 && e.message.contains('مسبق');

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
    var storeId = _order.storeId;
    if (storeId == null && _order.storeName.trim().isNotEmpty) {
      storeId = await _enricher.resolveStoreId(_order.storeName);
    }
    final enriched = <CartItem>[];
    for (final line in _order.items) {
      enriched.add(
        await _enricher.enrichLine(
          line,
          storeId: storeId,
          storeName: _order.storeName,
        ),
      );
    }
    if (!mounted) return;
    setState(() => _order = _order.copyWith(items: enriched, storeId: storeId));
  }

  Future<void> _pickImages(String productKey) async {
    final file = await _picker.pickImage(imageQuality: 85, source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _imageFiles[productKey] = [file]);
  }

  bool get _hasStoreSelection => !_storeAlreadyRated && _storeStars >= 1;

  bool _hasProductInput(String productKey) {
    if ((_productStars[productKey] ?? 0) >= 1) return true;
    final comment = _commentControllers[productKey]?.text.trim() ?? '';
    if (comment.isNotEmpty) return true;
    return (_imageFiles[productKey]?.isNotEmpty ?? false);
  }

  bool get _hasAnyProductSelection =>
      _pendingProducts.any((item) => _hasProductInput(item.product.name));

  /// يكفي حقل واحد: نجوم المتجر، أو نجوم/تعليق/صورة لأي منتج.
  bool get _canSubmit {
    if (_submitting) return false;
    return _hasStoreSelection || _hasAnyProductSelection;
  }

  /// API يتطلب نجوماً 1–5؛ إذا أرسل الزبون تعليقاً أو صورة فقط نستخدم 5.
  int _resolveProductStars(String productKey) {
    final stars = _productStars[productKey] ?? 0;
    if (stars >= 1) return stars.round().clamp(1, 5);
    return 5;
  }

  String _localizedOrRaw(BuildContext context, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    final translated = context.tr(trimmed);
    return translated == trimmed ? trimmed : translated;
  }

  Future<List<http.MultipartFile>> _multipartImages(String productKey) async {
    final xfiles = _imageFiles[productKey] ?? const [];
    if (xfiles.isEmpty) return const [];

    final files = <http.MultipartFile>[];
    for (var i = 0; i < xfiles.length; i++) {
      final xfile = xfiles[i];
      final bytes = await xfile.readAsBytes();
      final name = xfile.name.isNotEmpty ? xfile.name : 'rating_$i.jpg';
      files.add(
        http.MultipartFile.fromBytes(
          'images[$i]',
          bytes,
          filename: name,
          contentType: _imageMediaType(name),
        ),
      );
    }
    return files;
  }

  MediaType? _imageMediaType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    return MediaType('image', 'jpeg');
  }

  Future<void> _submit() async {
    if (!_canSubmit) {
      _showError(context.tr('rating_select_one'));
      return;
    }
    if (!AuthSession.instance.isAuthenticated) {
      _showError(context.tr('login_required_for_rating'));
      return;
    }

    setState(() => _submitting = true);

    final storeNotFoundMsg = context.tr('rating_store_not_found');
    final productNotFoundMsg = context.tr('rating_product_not_found');
    var sentCount = 0;

    try {
      if (_order.apiId != null) {
        final fresh = await OrdersApi().refreshOrderDetails(_order);
        if (!mounted) return;
        if (fresh.status != 'status_delivered') {
          _showError(context.tr('rating_order_not_delivered'));
          return;
        }
        setState(() => _order = fresh);
        await _enrichOrderItems();
        if (!mounted) return;
      }
      if (!_storeAlreadyRated && _storeStars >= 1) {
        var storeId = _order.storeId;
        storeId ??= await _enricher.resolveStoreId(_order.storeName);
        if (storeId == null) {
          throw ApiException(storeNotFoundMsg);
        }
        try {
          await _ratingsApi.rateStore(storeId: storeId, stars: _storeStars.round());
          _ratings.submitStoreRating(
            orderId: widget.order.id,
            storeKey: _order.storeName,
            rating: _storeStars,
          );
          sentCount++;
        } on ApiException catch (e) {
          if (_isStoreDuplicateError(e)) {
            _ratings.submitStoreRating(
              orderId: widget.order.id,
              storeKey: _order.storeName,
              rating: _storeStars,
            );
            sentCount++;
          } else {
            rethrow;
          }
        }
      }

      for (final item in _pendingProducts) {
        final key = item.product.name;
        if (!_hasProductInput(key)) continue;

        var productId = item.product.id ??
            await _enricher.resolveProductId(
              key,
              storeId: _order.storeId,
              storeName: _order.storeName,
            );
        if (productId == null) {
          throw ApiException('$productNotFoundMsg: $key');
        }

        final stars = _resolveProductStars(key);
        final imageFiles = await _multipartImages(key);
        final comment = _commentControllers[key]?.text;
        try {
          await _ratingsApi.rateProduct(
            productId: productId,
            stars: stars,
            comment: comment,
            imageFiles: imageFiles,
          );
          _ratings.submitProductRating(
            orderId: widget.order.id,
            productKey: key,
            rating: stars.toDouble(),
            comment: comment,
            imagePaths: (_imageFiles[key] ?? const []).map((x) => x.path).toList(),
          );
          sentCount++;
        } on ApiException catch (e) {
          if (_isProductDuplicateError(e)) {
            _ratings.submitProductRating(
              orderId: widget.order.id,
              productKey: key,
              rating: stars.toDouble(),
              comment: comment,
              imagePaths: (_imageFiles[key] ?? const []).map((x) => x.path).toList(),
            );
            sentCount++;
          } else {
            rethrow;
          }
        }
      }

      if (sentCount == 0) {
        _showError(context.tr('rating_select_one'));
        return;
      }

      await _ratings.markOrderRated(widget.order.id, apiId: _order.apiId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('rating_done'),
            style: GoogleFonts.cairo(),
          ),
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
    final productKeys = _order.items.map((e) => e.product.name).toList();
    final alreadyRated = _ratings.hasRatedOrder(
      widget.order.id,
      productKeys,
      apiId: _order.apiId,
    );

    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFF121026),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
        ),
      );
    }

    if (alreadyRated) {
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
                    context.tr('rating_done'),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
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
                          const SizedBox(height: 10),
                          Text(
                            context.tr('rating_optional_hint'),
                            style: GoogleFonts.cairo(color: Colors.white54, fontSize: 13, height: 1.4),
                          ),
                        ],
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
                    if (_order.items.isEmpty)
                      _card(
                        child: Text(
                          context.tr('rating_no_products'),
                          style: GoogleFonts.cairo(color: Colors.white54, fontSize: 14),
                        ),
                      )
                    else
                      for (var i = 0; i < _order.items.length; i++) ...[
                        _productRatingBlock(_order.items[i]),
                        if (i < _order.items.length - 1) const SizedBox(height: 16),
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
    final colorParts = <String>[];
    if (item.selectedColor.trim().isNotEmpty) {
      colorParts.add(_localizedOrRaw(context, item.selectedColor));
    }
    if (item.selectedSize.trim().isNotEmpty) colorParts.add(item.selectedSize);
    final colorSize = colorParts.join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _card(
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: StoreCoverImage(
                  imageUrl: _productImageUrl(item),
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
                      _localizedOrRaw(context, key),
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (colorSize.isNotEmpty) ...[
                      const SizedBox(height: 6),
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
        ),
        const SizedBox(height: 12),
        if (already)
          _card(
            child: Column(
              children: [
                _starRow(stars, null, size: 40),
                const SizedBox(height: 8),
                Text(
                  context.tr('products_rated_done'),
                  style: GoogleFonts.cairo(color: Colors.greenAccent, fontSize: 13),
                ),
              ],
            ),
          )
        else
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _starRow(stars, (v) => setState(() => _productStars[key] = v), size: 40),
                const SizedBox(height: 24),
                Text(
                  context.tr('rating_attach_photos'),
                  style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _pickImages(key),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(context.tr('rating_choose_photos'), style: GoogleFonts.cairo()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF3B82F6),
                    side: const BorderSide(color: Color(0xFF3B82F6)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.format(context, 'rating_photos_count', params: {
                    'count': '${_imageFiles[key]?.length ?? 0}',
                  }),
                  style: GoogleFonts.cairo(color: Colors.white54, fontSize: 13),
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
                const SizedBox(height: 10),
                TextField(
                  controller: _commentControllers[key],
                  onChanged: (_) => setState(() {}),
                  maxLines: 4,
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
            ),
          ),
      ],
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

  Widget _starRow(double value, ValueChanged<double>? onChanged, {double size = 36}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final star = (i + 1).toDouble();
        return IconButton(
          onPressed: onChanged == null ? null : () => onChanged(star),
          icon: Icon(
            value >= star ? Icons.star_rounded : Icons.star_border_rounded,
            color: Colors.amber,
            size: size,
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
