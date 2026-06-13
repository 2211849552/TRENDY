import '../../models/product.dart';
import '../../models/product_variant.dart';
import 'api_client.dart';
import 'customer_api_paths.dart';
import 'media_url.dart';
import 'product_variants_api.dart';

class ProductsApi {
  ProductsApi({ApiClient? client})
      : _client = client ?? ApiClient(),
        _variantsApi = ProductVariantsApi(client: client);

  final ApiClient _client;
  final ProductVariantsApi _variantsApi;

  /// GET /api/stores/{storeId}/products
  Future<List<Product>> fetchStoreProducts({
    required int storeId,
    required String storeName,
    String? name,
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    int perPage = 50,
  }) async {
    final query = <String, String>{'per_page': '$perPage'};
    if (name != null && name.trim().isNotEmpty) query['name'] = name.trim();
    if (categoryId != null) query['category_id'] = '$categoryId';
    if (minPrice != null) query['min_price'] = '${minPrice.toInt()}';
    if (maxPrice != null) query['max_price'] = '${maxPrice.toInt()}';

    final json = await _client.getFromRoot(
      CustomerApiPaths.storeProducts(storeId),
      query: query,
      withAuth: false,
    );

    final rows = _readList(json['data']);
    return rows
        .map((row) => _productFromList(row, storeName: storeName, storeId: storeId))
        .where((p) => p.id != null && p.id! > 0)
        .toList();
  }

  /// GET /api/products/{id}
  Future<Product> fetchProductDetails(int productId) async {
    final json = await _client.getFromRoot(CustomerApiPaths.product(productId), withAuth: false);
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
    return _productFromDetails(data);
  }

  /// GET /api/products/{id}/variants — ألوان ومقاسات متوفرة لكل منتج.
  Future<List<ProductVariantOption>> fetchProductVariants(int productId) {
    return _variantsApi.fetchVariants(productId);
  }

  /// GET /api/products/search?q=&per_page=
  Future<List<Product>> searchProducts({
    required String query,
    int perPage = 20,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    final json = await _client.getFromRoot(
      CustomerApiPaths.productSearch,
      query: {'q': q, 'per_page': '$perPage'},
      withAuth: false,
    );

    final rows = _readList(json['data']);
    return rows.map(_productFromList).where((p) => p.id != null && p.id! > 0).toList();
  }

  Product _productFromList(
    Map<String, dynamic> json, {
    String storeName = '',
    int? storeId,
  }) {
    final productId = _asInt(json['id']);
    final category = json['category'];
    var categoryName = '';
    if (category is Map) categoryName = '${category['name'] ?? ''}'.trim();

    final base = _asDouble(json['base_price']) ?? 0;
    final discounted = _asDouble(json['discounted_price']) ?? base;
    final hasDiscount = json['has_discount'] == true;
    final stock = _asInt(json['total_quantity']) ?? 0;

    final imageUrls = MediaUrl.productImagesFromJson(json['images'], productId: productId);
    var imageUrl = MediaUrl.productThumbnail(json['thumbnail'], productId: productId);
    if (imageUrl.isEmpty && imageUrls.isNotEmpty) imageUrl = imageUrls.first;

    return Product(
      id: productId,
      storeId: storeId,
      name: '${json['name'] ?? ''}'.trim(),
      code: '${json['sku'] ?? ''}'.trim().isEmpty ? null : '${json['sku']}'.trim(),
      category: categoryName.isNotEmpty ? categoryName : 'cat_all',
      price: discounted,
      originalPrice: hasDiscount ? base : null,
      rating: _asDouble(json['average_rating']) ?? 0,
      imageUrl: imageUrl,
      imageUrls: imageUrls.isNotEmpty ? imageUrls : (imageUrl.isNotEmpty ? [imageUrl] : const []),
      discount: hasDiscount ? _discountLabel(base, discounted) : null,
      storeName: storeName,
      isOutOfStock: stock <= 0,
      stockQuantity: stock,
    );
  }

  Product _productFromDetails(Map<String, dynamic> json) {
    final productId = _asInt(json['id']);
    final store = json['store'];
    var storeName = '';
    int? storeId;
    if (store is Map) {
      storeName = '${store['name'] ?? ''}'.trim();
      storeId = _asInt(store['id']);
    }

    final category = json['category'];
    var categoryName = '';
    if (category is Map) categoryName = '${category['name'] ?? ''}'.trim();

    final base = _asDouble(json['base_price']) ?? 0;
    final discounted = _asDouble(json['discounted_price']) ?? base;
    final hasDiscount = json['has_discount'] == true;
    final stock = _asInt(json['total_quantity']) ?? 0;

    final imageUrls = MediaUrl.productImagesFromJson(json['images'], productId: productId);
    var imageUrl = imageUrls.isNotEmpty
        ? imageUrls.first
        : MediaUrl.productThumbnail(json['thumbnail'], productId: productId);

    return Product(
      id: productId,
      storeId: storeId,
      name: '${json['name'] ?? ''}'.trim(),
      code: '${json['sku'] ?? ''}'.trim().isEmpty ? null : '${json['sku']}'.trim(),
      category: categoryName.isNotEmpty ? categoryName : 'cat_all',
      price: discounted,
      originalPrice: hasDiscount ? base : null,
      rating: _asDouble(json['average_rating']) ?? 0,
      imageUrl: imageUrl,
      imageUrls: imageUrls.isNotEmpty ? imageUrls : (imageUrl.isNotEmpty ? [imageUrl] : const []),
      discount: hasDiscount ? _discountLabel(base, discounted) : null,
      storeName: storeName,
      isOutOfStock: stock <= 0,
      stockQuantity: stock,
      description: '${json['description'] ?? ''}'.trim().isEmpty
          ? null
          : '${json['description']}'.trim(),
    );
  }

  String? _discountLabel(double base, double discounted) {
    if (base <= 0 || discounted >= base) return null;
    final percent = ((1 - discounted / base) * 100).round();
    if (percent <= 0) return null;
    return '-$percent%';
  }

  List<Map<String, dynamic>> _readList(dynamic raw) {
    if (raw is List) return raw.whereType<Map<String, dynamic>>().toList();
    return const [];
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }
}
