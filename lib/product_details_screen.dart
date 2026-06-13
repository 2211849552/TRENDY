import 'package:flutter/material.dart';
import 'data/product_color_variants.dart';
import 'theme/trendy_theme_extension.dart';
import 'widgets/product_gallery_section.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/product.dart';
import 'models/product_variant.dart';
import 'models/favorites_manager.dart';
import 'models/cart_manager.dart';
import 'models/auth_session.dart';
import 'l10n/app_strings.dart';
import 'services/api/api_exception.dart';
import 'services/api/products_api.dart';
import 'widgets/app_back_button.dart';
import 'widgets/product_comments_button.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final FavoritesManager _favoritesManager = FavoritesManager();
  final CartManager _cartManager = CartManager();
  final ProductsApi _productsApi = ProductsApi();

  late Product _product;
  late String _selectedColor;
  String _selectedSize = 'M';
  int _quantity = 1;
  bool _loading = false;
  bool _actionLoading = false;
  List<ProductVariantOption> _variants = [];

  late List<String> _colors;
  List<String> _sizes = ['S', 'M', 'L', 'XL', 'XXL'];
  bool _usesApiVariants = false;
  bool _sizesFilteredByColor = false;

  List<String> get _availableColors {
    if (!_usesApiVariants || _variants.isEmpty) return _colors;
    final values = <String>[];
    for (final variant in _variants) {
      final color = variant.colorValue;
      if (color != null && color.isNotEmpty && !values.contains(color)) {
        values.add(color);
      }
    }
    return values;
  }

  /// كل المقاسات من GET /api/products/{id}/variants
  List<String> get _allSizesFromVariants {
    if (!_usesApiVariants || _variants.isEmpty) return _sizes;
    final values = <String>[];
    for (final variant in _variants) {
      final size = variant.sizeValue;
      if (size != null && size.isNotEmpty && !values.contains(size)) {
        values.add(size);
      }
    }
    return _sortSizes(values);
  }

  List<String> get _sizesForSelectedColor {
    if (!_usesApiVariants || _variants.isEmpty) return _sizes;
    final values = <String>[];
    for (final variant in _variants) {
      final size = variant.sizeValue;
      if (size == null || size.isEmpty) continue;
      if (!_variantMatchesColor(variant, _selectedColor)) continue;
      if (!values.contains(size)) values.add(size);
    }
    return _sortSizes(values);
  }

  List<String> get _visibleSizes {
    if (!_usesApiVariants) return _sizes;
    if (!_sizesFilteredByColor) return _allSizesFromVariants;
    return _sizesForSelectedColor;
  }

  bool get _showSizeSection =>
      !_usesApiVariants ? _sizes.isNotEmpty : _allSizesFromVariants.isNotEmpty;

  List<String> _sortSizes(List<String> sizes) {
    const order = ['XXS', 'XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL', '2XL', '3XL', '4XL'];
    final copy = List<String>.from(sizes);
    copy.sort((a, b) {
      final ai = order.indexOf(a.toUpperCase());
      final bi = order.indexOf(b.toUpperCase());
      if (ai >= 0 && bi >= 0) return ai.compareTo(bi);
      if (ai >= 0) return -1;
      if (bi >= 0) return 1;
      return a.compareTo(b);
    });
    return copy;
  }

  bool _variantMatchesColor(ProductVariantOption variant, String selectedColor) {
    final colors = _availableColors;
    if (colors.isEmpty) return true;
    final color = variant.colorValue ?? '';
    return color.isEmpty || color == selectedColor;
  }

  bool _isSizeAvailable(String size) {
    if (!_usesApiVariants) return true;
    if (!_sizesFilteredByColor) {
      return _variants.any((variant) => variant.sizeValue == size && variant.stock > 0);
    }
    return _variants.any(
      (variant) =>
          _variantMatchesColor(variant, _selectedColor) &&
          variant.sizeValue == size &&
          variant.stock > 0,
    );
  }

  void _applyVariantSelectionFromApi() {
    final colors = _availableColors;
    if (colors.isNotEmpty) {
      _colors = colors;
      if (!_colors.contains(_selectedColor)) _selectedColor = _colors.first;
    }

    _sizesFilteredByColor = false;
    final allSizes = _allSizesFromVariants;
    if (allSizes.isNotEmpty) {
      _sizes = allSizes;
      if (!_sizes.contains(_selectedSize)) {
        _selectedSize = _sizes.firstWhere(_isSizeAvailable, orElse: () => _sizes.first);
      }
    }

    _syncPriceFromVariant();
  }

  void _onColorSelected(String color) {
    setState(() {
      _selectedColor = color;
      _sizesFilteredByColor = true;
      final sizes = _sizesForSelectedColor;
      if (sizes.isNotEmpty) {
        _sizes = sizes;
        if (!_sizes.contains(_selectedSize)) {
          _selectedSize = _sizes.firstWhere(_isSizeAvailable, orElse: () => _sizes.first);
        }
      }
      _syncPriceFromVariant();
    });
  }

  void _syncPriceFromVariant() {
    final variant = _selectedVariant;
    if (variant == null) return;
    _product = _product.copyWith(
      price: variant.price,
      originalPrice: variant.originalPrice > variant.price ? variant.originalPrice : null,
      isOutOfStock: variant.stock <= 0,
      stockQuantity: variant.stock,
    );
    _clampQuantity();
  }

  int get _maxQuantity {
    final variant = _selectedVariant;
    if (variant != null && variant.stock > 0) return variant.stock;
    final stock = _product.stockQuantity;
    if (stock != null && stock > 0) return stock;
    return _product.isOutOfStock ? 0 : 99;
  }

  void _clampQuantity() {
    final max = _maxQuantity;
    if (max <= 0) {
      _quantity = 1;
      return;
    }
    if (_quantity > max) _quantity = max;
    if (_quantity < 1) _quantity = 1;
  }

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _initSelectionDefaults();
    _loadFromApi();
  }

  /// بيانات افتراضية محلية فقط للمنتجات بدون معرّف API.
  void _initSelectionDefaults() {
    final hasApiId = _product.id != null && _product.id! > 0;
    if (hasApiId) {
      _colors = const [];
      _selectedColor = '';
      _sizes = const [];
      _selectedSize = '';
      return;
    }
    _colors = ProductColorVariants.colorsFor(_product.name);
    _selectedColor = ProductColorVariants.defaultColorFor(_product.name);
    _sizes = const ['S', 'M', 'L', 'XL', 'XXL'];
    _selectedSize = 'M';
  }

  Future<int?> _resolveProductId() async {
    final name = _product.name.trim();
    if (name.isEmpty) return null;

    final storeId = _product.storeId;
    final storeName = _product.storeName;
    if (storeId != null && storeId > 0) {
      final rows = await _productsApi.fetchStoreProducts(
        storeId: storeId,
        storeName: storeName,
        name: name,
        perPage: 20,
      );
      for (final candidate in rows) {
        if (candidate.name.trim() == name) return candidate.id;
      }
      if (rows.isNotEmpty) return rows.first.id;
    }

    final search = await _productsApi.searchProducts(query: name, perPage: 20);
    for (final candidate in search) {
      if (candidate.name.trim() == name) return candidate.id;
    }
    return search.isNotEmpty ? search.first.id : null;
  }

  Future<void> _loadFromApi() async {
    setState(() => _loading = true);
    try {
      var productId = _product.id;
      if (productId == null || productId <= 0) {
        productId = await _resolveProductId();
      }
      if (productId == null || productId <= 0) return;

      final previousImageUrl = _product.imageUrl;
      final previousImageUrls = _product.imageUrls;

      final detailsFuture = _productsApi.fetchProductDetails(productId);
      final variantsFuture = _productsApi.fetchProductVariants(productId);
      final details = await detailsFuture;
      final variants = await variantsFuture;
      if (!mounted) return;

      _product = details.copyWith(
        id: productId,
        storeName: details.storeName.isNotEmpty ? details.storeName : _product.storeName,
        storeId: details.storeId ?? _product.storeId,
        imageUrl: details.imageUrl.isNotEmpty ? details.imageUrl : previousImageUrl,
        imageUrls: details.imageUrls.isNotEmpty ? details.imageUrls : previousImageUrls,
      );
      _variants = variants;
      _usesApiVariants = variants.isNotEmpty;

      if (_usesApiVariants) {
        _applyVariantSelectionFromApi();
      } else {
        _colors = const [];
        _sizes = const [];
        _selectedColor = '';
        _selectedSize = '';
      }
    } on ApiException {
      // نُبقي بيانات المنتج المُمرَّرة.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  ProductVariantOption? get _selectedVariant {
    if (_variants.isEmpty) return null;
    for (final variant in _variants) {
      final color = variant.colorValue ?? '';
      final size = variant.sizeValue ?? '';
      final colorMatch = _availableColors.isEmpty ||
          color.isEmpty ||
          !_sizesFilteredByColor ||
          color == _selectedColor;
      final sizeMatch = _visibleSizes.isEmpty || size.isEmpty || size == _selectedSize;
      if (colorMatch && sizeMatch) return variant;
    }
    return _variants.firstWhere((v) => v.stock > 0, orElse: () => _variants.first);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.trendy.pageBackground,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Directionality(
                textDirection: context.isRtl ? TextDirection.rtl : TextDirection.ltr,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ProductGallerySection(
                          imageUrl: _product.imageUrl,
                          imageUrls: _product.imageUrls,
                          productKey: _product.name,
                          storeName: _product.storeName,
                        ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withValues(alpha: 0.35),
                        child: AppBackIconButton(
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMainHeader(),
                      const SizedBox(height: 24),
                      _buildPriceSection(),
                      const SizedBox(height: 32),
                      _buildDescriptionBox(),
                      const SizedBox(height: 12),
                      ProductCommentsButton(
                        product: _product,
                        variantLabel: _usesApiVariants && _selectedColor.isNotEmpty
                            ? '${_variantDisplayLabel(_selectedColor)} · $_selectedSize'
                            : null,
                      ),
                      if (_availableColors.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _buildSelectionLabel(context.tr('color')),
                        const SizedBox(height: 16),
                        _buildColorSelector(),
                      ],
                      if (_showSizeSection) ...[
                        const SizedBox(height: 32),
                        _buildSelectionLabel(context.tr('size')),
                        const SizedBox(height: 16),
                        _buildSizeSelector(),
                      ],
                      const SizedBox(height: 32),
                      
                      // Quantity Selection
                      _buildSelectionLabel(context.tr('quantity')),
                      const SizedBox(height: 8),
                      if (_maxQuantity > 0)
                        Text(
                          AppStrings.format(context, 'max_quantity_label', params: {
                            'count': '$_maxQuantity',
                          }),
                          style: GoogleFonts.cairo(color: Colors.white54, fontSize: 13),
                        ),
                      const SizedBox(height: 8),
                      _buildQuantitySelector(),
                      
                      const SizedBox(height: 48),
                      
                      // Action Buttons
                      _buildActionButtons(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
                  ],
                ),
              ),
            ),
            if (_loading)
              const Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(_product.name),
                style: GoogleFonts.cairo(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA855F7).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      context.tr(_product.category),
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF3B82F6),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${_product.rating}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${_product.price}${context.tr('currency_suffix')}',
              style: GoogleFonts.cairo(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3B82F6),
              ),
            ),
            if (_product.originalPrice != null)
              Text(
                '${_product.originalPrice}${context.tr('currency_suffix')}',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white24,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            if (_product.discount != null && _product.discount!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_product.discount} ${context.tr('sort_offers').split(' ')[0]}',
                  style: const TextStyle(
                    color: Color(0xFF3B82F6),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _product.isOutOfStock ? context.tr('out_of_stock') : context.tr('available'),
          style: TextStyle(
            color: _product.isOutOfStock ? Colors.redAccent : Colors.greenAccent,
            fontWeight: FontWeight.bold, 
            fontSize: 14
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFA855F7).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        _product.description?.isNotEmpty == true
            ? _product.description!
            : context.tr('product_description_placeholder'),
        style: GoogleFonts.cairo(
          fontSize: 15,
          color: Colors.white70,
          height: 1.6,
        ),
      ),
    );
  }

  String _variantDisplayLabel(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    final translated = context.tr(trimmed);
    return translated == trimmed ? trimmed : translated;
  }

  Widget _buildSelectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildColorSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _availableColors.map((color) {
        final isSelected = _selectedColor == color;
        return GestureDetector(
          onTap: () => _onColorSelected(color),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFA855F7).withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF3B82F6) : Colors.white10,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              _variantDisplayLabel(color),
              style: GoogleFonts.cairo(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSizeSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _visibleSizes.map((size) {
        final isSelected = _selectedSize == size;
        final available = _isSizeAvailable(size);
        return GestureDetector(
          onTap: available
              ? () => setState(() {
                    _selectedSize = size;
                    _syncPriceFromVariant();
                  })
              : null,
          child: Opacity(
            opacity: available ? 1 : 0.35,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFA855F7) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFF3B82F6) : Colors.white10,
                ),
              ),
              child: Text(
                size,
                style: TextStyle(
                  color: available ? Colors.white : Colors.white54,
                  fontWeight: FontWeight.bold,
                  decoration: available ? null : TextDecoration.lineThrough,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuantitySelector() {
    final maxQty = _maxQuantity;
    final canIncrease = maxQty > 0 && _quantity < maxQty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.white54, size: 20),
            onPressed: () {
              if (_quantity > 1) setState(() => _quantity--);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '$_quantity',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.add,
              color: canIncrease ? const Color(0xFF3B82F6) : Colors.white24,
              size: 20,
            ),
            onPressed: canIncrease
                ? () => setState(() {
                      if (_quantity < maxQty) _quantity++;
                    })
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final isFav = _favoritesManager.isFavorite(_product);

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: (_actionLoading || _product.isOutOfStock) ? null : _addToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA855F7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_basket_outlined, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    context.tr('nav_cart'),
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        // Favorite Button (Now on the Left/End of Row)
        GestureDetector(
          onTap: _actionLoading ? null : _toggleFavorite,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isFav ? const Color(0xFFA855F7) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isFav ? const Color(0xFF3B82F6) : Colors.white10),
            ),
            child: Icon(
              isFav ? Icons.favorite : Icons.favorite_outline,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _addToCart() async {
    if (!AuthSession.instance.isAuthenticated) {
      _showSnack(context.tr('cart_login_prompt'), isError: true);
      return;
    }

    final variant = _selectedVariant;
    if (_product.id != null && variant == null) {
      _showSnack(context.tr('out_of_stock'), isError: true);
      return;
    }
    if (_usesApiVariants && !_sizesFilteredByColor) {
      _showSnack(context.tr('select_color_first'), isError: true);
      return;
    }
    if (_usesApiVariants && !_isSizeAvailable(_selectedSize)) {
      _showSnack(context.tr('out_of_stock'), isError: true);
      return;
    }
    if (_maxQuantity <= 0) {
      _showSnack(context.tr('out_of_stock'), isError: true);
      return;
    }
    if (_quantity > _maxQuantity) {
      _showSnack(
        AppStrings.format(context, 'max_quantity_label', params: {'count': '$_maxQuantity'}),
        isError: true,
      );
      return;
    }

    setState(() => _actionLoading = true);
    try {
      await _cartManager.addToCart(
        _product,
        color: _selectedColor,
        size: _selectedSize,
        quantity: _quantity,
        variantId: variant?.id,
      );
      if (!mounted) return;
      _showSnack(context.tr('added_to_cart_msg'));
    } on CartSingleStoreException {
      if (!mounted) return;
      _showSnack(context.tr('cart_single_store_error'), isError: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    if (!AuthSession.instance.isAuthenticated) {
      _showSnack(context.tr('wallet_login_required'), isError: true);
      return;
    }
    if (_product.id == null) {
      await _favoritesManager.toggleFavorite(_product);
      if (!mounted) return;
      setState(() {});
      return;
    }

    setState(() => _actionLoading = true);
    try {
      final wasFavorite = _favoritesManager.isFavorite(_product);
      await _favoritesManager.toggleFavorite(_product);
      if (!mounted) return;
      if (!wasFavorite) _showSnack(context.tr('added_to_fav'));
      setState(() {});
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent : const Color(0xFFA855F7).withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 100,
          left: 20,
          right: 20,
        ),
        content: Text(message, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}
