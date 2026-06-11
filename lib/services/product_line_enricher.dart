import '../data/product_images.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/product_variant.dart';
import '../widgets/store_cover_image.dart';
import 'api/api_exception.dart';
import 'api/products_api.dart';
import 'api/stores_api.dart';

/// إثراء عناصر السلة/الطلبات بصور وتنوعات — لأن GET /api/cart و GET /api/orders لا يُرجعان صوراً.
class ProductLineEnricher {
  ProductLineEnricher({
    ProductsApi? productsApi,
    StoresApi? storesApi,
  })  : _productsApi = productsApi ?? ProductsApi(),
        _storesApi = storesApi ?? StoresApi();

  final ProductsApi _productsApi;
  final StoresApi _storesApi;

  final Map<String, int> _productIdByName = {};
  final Map<int, String> _imageByProductId = {};
  final Map<String, String> _imageByProductName = {};
  final Map<int, List<ProductVariantOption>> _variantsByProductId = {};

  Future<int?> resolveProductId(
    String productName, {
    int? storeId,
    String? storeName,
  }) async {
    final name = productName.trim();
    if (name.isEmpty) return null;
    final cacheKey = storeId != null ? '$storeId::$name' : name;
    if (_productIdByName.containsKey(cacheKey)) return _productIdByName[cacheKey];
    if (_productIdByName.containsKey(name)) return _productIdByName[name];

    try {
      Product? matched;

      if (storeId != null && storeId > 0) {
        final storeResults = await _productsApi.fetchStoreProducts(
          storeId: storeId,
          storeName: storeName ?? '',
          name: name,
          perPage: 15,
        );
        for (final candidate in storeResults) {
          if (candidate.name.trim() == name) {
            matched = candidate;
            break;
          }
        }
        matched ??= storeResults.isNotEmpty ? storeResults.first : null;
      }

      if (matched == null) {
        final results = await _productsApi.searchProducts(query: name, perPage: 15);
        for (final candidate in results) {
          if (candidate.name.trim() == name) {
            matched = candidate;
            break;
          }
        }
        matched ??= results.isNotEmpty ? results.first : null;
      }

      if (matched?.id != null) {
        _productIdByName[cacheKey] = matched!.id!;
        _productIdByName[name] = matched.id!;
        if (matched.imageUrl.isNotEmpty) {
          _rememberImage(name: name, productId: matched.id!, imageUrl: matched.imageUrl);
        }
        return matched.id;
      }
    } on ApiException {
      return null;
    }
    return null;
  }

  Future<String?> resolveImageUrl({
    required String productName,
    int? productId,
    int? storeId,
    String? storeName,
  }) async {
    final name = productName.trim();
    final cached = _imageByProductName[name];
    if (cached != null && cached.isNotEmpty) return cached;

    final id = productId ??
        await resolveProductId(name, storeId: storeId, storeName: storeName);
    if (id == null) return null;

    final byId = _imageByProductId[id];
    if (byId != null && byId.isNotEmpty) return byId;

    try {
      final details = await _productsApi.fetchProductDetails(id);
      if (details.imageUrl.isNotEmpty) {
        _rememberImage(name: name, productId: id, imageUrl: details.imageUrl);
        return details.imageUrl;
      }
    } on ApiException {
      return null;
    }
    return null;
  }

  Future<ProductVariantOption?> variantById(int productId, int variantId) async {
    final variants = await _loadVariants(productId);
    for (final variant in variants) {
      if (variant.id == variantId) return variant;
    }
    return null;
  }

  Future<List<ProductVariantOption>> _loadVariants(int productId) async {
    if (_variantsByProductId.containsKey(productId)) {
      return _variantsByProductId[productId]!;
    }
    try {
      final variants = await _productsApi.fetchProductVariants(productId);
      _variantsByProductId[productId] = variants;
      return variants;
    } on ApiException {
      return const [];
    }
  }

  Future<CartItem> enrichLine(
    CartItem line, {
    int? storeId,
    String? storeName,
  }) async {
    final name = line.product.name.trim();
    if (name.isEmpty) return line;

    final resolvedStoreId = storeId ?? line.product.storeId;
    final resolvedStoreName = storeName ?? line.product.storeName;

    final productId = line.product.id ??
        await resolveProductId(
          name,
          storeId: resolvedStoreId,
          storeName: resolvedStoreName,
        );
    var imageUrl = line.product.imageUrl;
    if (imageUrl.isEmpty) {
      imageUrl = await resolveImageUrl(
            productName: name,
            productId: productId,
            storeId: resolvedStoreId,
            storeName: resolvedStoreName,
          ) ??
          '';
    }
    if (imageUrl.isEmpty) {
      final asset = ProductImages.forProductKey(name);
      if (StoreCoverImage.isAssetPath(asset)) imageUrl = asset;
    }

    var color = line.selectedColor;
    var size = line.selectedSize;
    if (productId != null && line.variantId != null && (color.isEmpty || size.isEmpty)) {
      final variant = await variantById(productId, line.variantId!);
      if (variant != null) {
        if (color.isEmpty) color = variant.colorValue ?? color;
        if (size.isEmpty) size = variant.sizeValue ?? size;
      }
    }

    return CartItem(
      product: line.product.copyWith(
        id: productId ?? line.product.id,
        imageUrl: imageUrl,
      ),
      selectedColor: color,
      selectedSize: size,
      quantity: line.quantity,
      variantId: line.variantId,
      apiItemId: line.apiItemId,
      availableStock: line.availableStock,
    );
  }

  Future<int?> resolveStoreId(String storeName) async {
    final name = storeName.trim();
    if (name.isEmpty) return null;
    try {
      final stores = await _storesApi.fetchStores(name: name, perPage: 10);
      for (final store in stores) {
        if (store.displayName.trim() == name) return store.id;
      }
      return stores.isNotEmpty ? stores.first.id : null;
    } on ApiException {
      return null;
    }
  }

  void _rememberImage({
    required String name,
    required int productId,
    required String imageUrl,
  }) {
    _productIdByName[name] = productId;
    _imageByProductId[productId] = imageUrl;
    _imageByProductName[name] = imageUrl;
  }
}
