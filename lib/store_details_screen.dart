import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'l10n/app_strings.dart';
import 'models/product.dart';
import 'models/ratings_manager.dart';
import 'services/store_location.dart';
import 'product_details_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chat/chat_with_store_screen.dart';
import 'widgets/app_back_button.dart';
import 'theme/app_colors.dart';
import 'theme/trendy_theme_extension.dart';
import 'widgets/store_cover_image.dart';
import 'widgets/store_delivery_meta.dart';
import 'data/store_products_data.dart';
import 'services/api/products_api.dart';
import 'services/api/stores_api.dart';
import 'services/api/api_exception.dart';

class StoreDetailsScreen extends StatefulWidget {
  final String storeName;
  final String? storeDisplayName;

  /// معرف المتجر في API — يُستخدم لمحادثة الخادم (زبون ↔ متجر).
  final int? storeId;
  final String storeCategory;
  final double storeRating;
  final String storeDistance;
  final String storeImageUrl;
  final String? storeDiscount;
  final StoreLocation? storeLocation;

  /// رابط موقع المتجر في Google Maps (حقل google_map_url من API).
  final String? storeMapUrl;
  final bool isElectronic;
  final double deliveryFee;

  const StoreDetailsScreen({
    super.key,
    required this.storeName,
    this.storeDisplayName,
    this.storeId,
    required this.storeCategory,
    required this.storeRating,
    required this.storeDistance,
    required this.storeImageUrl,
    required this.isElectronic,
    required this.deliveryFee,
    this.storeDiscount,
    this.storeLocation,
    this.storeMapUrl,
  });

  @override
  State<StoreDetailsScreen> createState() => _StoreDetailsScreenState();
}

class _StoreDetailsScreenState extends State<StoreDetailsScreen> {
  final RatingsManager _ratingsManager = RatingsManager();
  RangeValues _priceRange = const RangeValues(0, 1500);
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late List<Product> _allProducts;
  late double _maxProductPrice;
  bool _openingMap = false;
  bool _loadingProducts = false;
  String? _productsError;
  String _storeImageUrl = '';
  final ProductsApi _productsApi = ProductsApi();

  Future<void> _refreshStoreLogoFromApi() async {
    final id = widget.storeId;
    if (id == null || id <= 0) return;
    try {
      final store = await StoresApi().fetchStore(id);
      if (!mounted || store.imageUrl.isEmpty) return;
      setState(() => _storeImageUrl = store.imageUrl);
    } catch (_) {
      // نُبقي الصورة المُمرَّرة من قائمة المتاجر.
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// هل يوجد موقع جغرافي للمتجر (رابط Google Maps من API أو إحداثيات محلية)؟
  bool get _hasMapTarget =>
      (widget.storeMapUrl?.trim().isNotEmpty ?? false) || widget.storeLocation != null;

  Future<void> _openInGoogleMaps() async {
    Uri? uri;
    final mapUrl = widget.storeMapUrl?.trim();
    if (mapUrl != null && mapUrl.isNotEmpty) {
      uri = Uri.tryParse(mapUrl);
    } else if (widget.storeLocation != null) {
      final loc = widget.storeLocation!;
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${loc.lat},${loc.lng}&travelmode=driving',
      );
    }
    if (uri == null) return;

    setState(() => _openingMap = true);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('map_open_failed'), style: GoogleFonts.cairo())),
        );
      }
    } finally {
      if (mounted) setState(() => _openingMap = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _storeImageUrl = widget.storeImageUrl;
    _allProducts = _getMockProducts(
      widget.storeCategory,
      widget.storeName,
      widget.storeDiscount != null,
    );
    _recalculatePriceRange();
    _refreshStoreLogoFromApi();
    _loadProductsFromApi();
  }

  void _recalculatePriceRange() {
    _maxProductPrice = _allProducts.fold<double>(
      1500,
      (max, p) => p.price > max ? p.price : max,
    );
    _priceRange = RangeValues(0, _maxProductPrice.ceilToDouble());
  }

  Future<void> _loadProductsFromApi() async {
    final storeId = widget.storeId;
    if (storeId == null || storeId <= 0) return;

    setState(() {
      _loadingProducts = true;
      _productsError = null;
    });

    try {
      final storeLabel = widget.storeDisplayName ?? widget.storeName;
      final products = await _productsApi.fetchStoreProducts(
        storeId: storeId,
        storeName: storeLabel,
        minPrice: _priceRange.start > 0 ? _priceRange.start : null,
        maxPrice: _priceRange.end < _maxProductPrice ? _priceRange.end : null,
        name: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
      );
      if (!mounted) return;
      setState(() {
        _allProducts = products;
        _recalculatePriceRange();
        _loadingProducts = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _productsError = e.message;
        _loadingProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _productsError = e.toString();
        _loadingProducts = false;
      });
    }
  }

  List<Product> _getMockProducts(String storeCat, String storeNameKey, bool hasStoreDiscount) {
    List<Product> products = _generateRawProducts(storeCat, storeNameKey);
    
    if (!hasStoreDiscount) {
      return products.map((p) => Product(
        name: p.name,
        code: p.code ?? _buildProductCode(p.name),
        category: p.category,
        price: p.price,
        originalPrice: null,
        rating: p.rating,
        imageUrl: p.imageUrl,
        discount: null,
        storeName: p.storeName,
        isOutOfStock: p.isOutOfStock,
      )).toList();
    }
    return products
        .map(
          (p) => Product(
            name: p.name,
            code: p.code ?? _buildProductCode(p.name),
            category: p.category,
            price: p.price,
            originalPrice: p.originalPrice,
            rating: p.rating,
            imageUrl: p.imageUrl,
            discount: p.discount,
            storeName: p.storeName,
            isOutOfStock: p.isOutOfStock,
          ),
        )
        .toList();
  }

  String _buildProductCode(String key) {
    return key.replaceFirst('prod_', '').replaceAll('_', '-').toUpperCase();
  }

  List<Product> _generateRawProducts(String storeCat, String storeNameKey) {
    return StoreProductsData.productsFor(storeNameKey);
  }


  List<Product> get _filteredProducts {
    return _allProducts.where((p) {
      final inPrice = p.price >= _priceRange.start && p.price <= _priceRange.end;
      if (!inPrice) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final name = context.tr(p.name).toLowerCase();
      final code = (p.code ?? p.name).toLowerCase();
      return name.contains(q) || code.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ratingsManager,
      builder: (context, _) => Scaffold(
        backgroundColor: context.trendy.pageBackground,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStoreHeader(),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildProductSearchBar(),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildPriceFilter(),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                context.tr('products'),
                                style: GoogleFonts.cairo(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Text(
                              '${_filteredProducts.length} ${context.tr('products')}',
                              style: GoogleFonts.cairo(fontSize: 13, color: Colors.white54),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_loadingProducts)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_productsError != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              _productsError!,
                              style: GoogleFonts.cairo(color: Colors.redAccent, fontSize: 13),
                            ),
                          )
                        else if (_filteredProducts.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Column(
                                children: [
                                  const Icon(Icons.price_change_outlined, color: Colors.white30, size: 40),
                                  const SizedBox(height: 12),
                                  Text(
                                    context.tr('no_orders_filter'),
                                    style: GoogleFonts.cairo(
                                      fontSize: 16,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextButton.icon(
                                    onPressed: () => setState(
                                      () => _priceRange = RangeValues(0, _maxProductPrice.ceilToDouble()),
                                    ),
                                    icon: const Icon(Icons.refresh_rounded, color: Color(0xFF3B82F6), size: 16),
                                    label: Text(
                                      context.tr('view_all_orders'),
                                      style: GoogleFonts.cairo(color: const Color(0xFF3B82F6), fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          LayoutBuilder(
                            builder: (context, constraints) {
                              const gap = 12.0;
                              final crossAxisCount =
                                  constraints.maxWidth >= 520 ? 3 : 2;
                              final cellWidth = (constraints.maxWidth -
                                      gap * (crossAxisCount - 1)) /
                                  crossAxisCount;
                              final cardHeight =
                                  (cellWidth * 1.45).clamp(200.0, 280.0);
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: gap,
                                  crossAxisSpacing: gap,
                                  mainAxisExtent: cardHeight,
                                ),
                                itemCount: _filteredProducts.length,
                                itemBuilder: (context, index) {
                                  return _buildProductCard(
                                    _filteredProducts[index],
                                    cardHeight: cardHeight,
                                  );
                                },
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoreHeader() {
    final isApiLogo = StoreCoverImage.isRemoteUrl(_storeImageUrl);
    final coverProvider = StoreCoverImage.imageProvider(
      isApiLogo ? '' : _storeImageUrl,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: isApiLogo || coverProvider == null
                    ? LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.55),
                          Theme.of(context).colorScheme.secondary.withValues(alpha: 0.35),
                          context.trendy.pageBackground,
                        ],
                      )
                    : null,
                image: coverProvider != null
                    ? DecorationImage(image: coverProvider, fit: BoxFit.cover)
                    : null,
              ),
              child: isApiLogo
                  ? Center(
                      child: StoreCoverImage(
                        imageUrl: _storeImageUrl,
                        asLogo: true,
                        width: 120,
                        height: 120,
                      ),
                    )
                  : null,
            ),
            Positioned(
              top: 12,
              right: 12,
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.black.withValues(alpha: 0.35),
                child: AppBackIconButton(
                  iconSize: 22,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.95),
                  Theme.of(context).colorScheme.secondary.withValues(alpha: 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_allProducts.any((p) => p.discount != null && p.discount!.isNotEmpty))
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.pinkAccent.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          context.tr('special_offers'),
                          style: GoogleFonts.cairo(
                            color: Colors.pinkAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (_allProducts.any((p) => p.discount != null && p.discount!.isNotEmpty))
                      const SizedBox(width: 10),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.storeDisplayName ?? context.tr(widget.storeName),
                              textAlign: TextAlign.right,
                              style: GoogleFonts.cairo(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          _buildStoreHeaderIcon(
                            icon: Icons.chat_bubble_outline,
                            tooltip: context.tr('chat_open'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatWithStoreScreen(
                                    storeKey: widget.storeName,
                                    storeId: widget.storeId,
                                    storeDisplayName: widget.storeDisplayName,
                                  ),
                                ),
                              );
                            },
                          ),
                          // الموقع الجغرافي للمتجر في Google Maps (بدل الشعار)
                          if (_hasMapTarget) ...[
                            const SizedBox(width: 12),
                            _buildStoreHeaderIcon(
                              icon: Icons.location_on_outlined,
                              tooltip: context.tr('open_in_maps'),
                              onPressed: _openingMap ? null : _openInGoogleMaps,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                StoreDeliveryMeta(
                  rating: widget.storeRating,
                  deliveryFee: widget.deliveryFee,
                  distanceText: widget.storeDistance,
                  isElectronic: widget.isElectronic,
                  compact: false,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Colors.white54, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        context.tr('store_address'),
                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Text(
                      context.tr('categories_label'),
                      style: const TextStyle(
                        color: const Color(0xFF3B82F6),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    ..._allProducts.map((p) => p.category).toSet().map(_buildTag),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStoreHeaderIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 40,
            height: 40,
            child: onPressed == null && _openingMap
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(context.tr(label), style: const TextStyle(color: Colors.white70, fontSize: 11)),
    );
  }

  Widget _buildProductSearchBar() {
    return TextField(
      controller: _searchController,
      textAlign: TextAlign.right,
      style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
      onChanged: (v) => setState(() => _searchQuery = v.trim()),
      decoration: InputDecoration(
        hintText: context.tr('search_product'),
        hintStyle: GoogleFonts.cairo(color: Colors.white38, fontSize: 13),
        prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: const Color(0xFF3B82F6)),
        ),
      ),
    );
  }

  Widget _buildPriceFilter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFA855F7).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('filter_products'),
            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            '${context.tr('price_range')} ${_priceRange.start.toInt()} - ${_priceRange.end.toInt()}${context.tr('currency_suffix')}',
            style: GoogleFonts.cairo(fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w600),
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: _maxProductPrice.ceilToDouble(),
            divisions: _maxProductPrice > 100 ? 20 : null,
            activeColor: AppColors.primary,
            inactiveColor: Colors.white10,
            onChanged: (values) => setState(() => _priceRange = values),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product p, {required double cardHeight}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(product: p),
          ),
        );
      },
      child: SizedBox(
        height: cardHeight,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFA855F7).withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 7,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: StoreCoverImage(
                        imageUrl: p.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  if (p.discount != null && p.discount!.isNotEmpty)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          p.discount!,
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  const Positioned(
                    top: 10,
                    left: 10,
                    child: Icon(Icons.favorite_outline, color: Colors.white, size: 20),
                  ),
                  if (p.isOutOfStock)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(8)),
                            child: Text(context.tr('out_of_stock'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(p.name),
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 12),
                          const SizedBox(width: 3),
                          Text(
                            _ratingsManager
                                .productRatingOrBase(p.name, p.rating)
                                .toStringAsFixed(1),
                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '${p.price}${context.tr('currency_suffix')}',
                            style: const TextStyle(
                              color: Color(0xFF3B82F6),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          if (p.originalPrice != null)
                            Text(
                              '${p.originalPrice}${context.tr('currency_suffix')}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white24,
                                fontSize: 9,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
