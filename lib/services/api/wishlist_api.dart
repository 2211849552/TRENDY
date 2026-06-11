import '../../models/product.dart';
import 'api_client.dart';
import 'media_url.dart';

class WishlistApi {
  WishlistApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// GET /api/wishlist
  Future<List<Product>> fetchWishlist() async {
    final json = await _client.getFromRoot('/wishlist');
    final rows = json['data'];
    if (rows is! List) return const [];

    return rows.whereType<Map<String, dynamic>>().map(_productFromJson).toList();
  }

  /// POST /api/wishlist — body: product_id
  Future<void> addProduct(int productId) async {
    await _client.postFromRoot('/wishlist', body: {'product_id': productId});
  }

  /// DELETE /api/wishlist/{productId}
  Future<void> removeProduct(int productId) async {
    await _client.deleteFromRoot('/wishlist/$productId');
  }

  /// POST /api/wishlist/{productId}/move-to-cart — body: variant_id
  Future<void> moveToCart({required int productId, required int variantId}) async {
    await _client.postFromRoot(
      '/wishlist/$productId/move-to-cart',
      body: {'variant_id': variantId},
    );
  }

  Product _productFromJson(Map<String, dynamic> json) {
    final id = _asInt(json['product_id'] ?? json['id']) ?? 0;
    final price = _asDouble(json['price']) ?? 0;
    return Product(
      id: id > 0 ? id : null,
      name: '${json['name'] ?? ''}'.trim(),
      category: 'cat_all',
      price: price,
      rating: 0,
      imageUrl: MediaUrl.productThumbnail(json['image'], productId: id > 0 ? id : null),
      storeName: '',
      isOutOfStock: json['is_available'] == false,
    );
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
