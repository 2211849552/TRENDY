import '../../models/product_variant.dart';
import 'api_client.dart';
import 'customer_api_paths.dart';

/// تنوعات المنتج (لون / مقاس / مخزون) — GET /api/products/{id}/variants
/// انظر `lib/api.md` [5.3] و [ProductController::variants].
class ProductVariantsApi {
  ProductVariantsApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// GET /api/products/{productId}/variants
  Future<List<ProductVariantOption>> fetchVariants(int productId) async {
    if (productId <= 0) return const [];

    final json = await _client.getFromRoot(
      CustomerApiPaths.productVariants(productId),
      withAuth: false,
    );
    return parseVariantsResponse(json);
  }

  /// يحلّل `{ "variants": [ … ] }` أو `{ "data": [ … ] }`.
  static List<ProductVariantOption> parseVariantsResponse(Map<String, dynamic> json) {
    final rows = json['variants'] ?? json['data'];
    if (rows is! List) return const [];

    return rows
        .whereType<Map<String, dynamic>>()
        .map(ProductVariantOption.fromJson)
        .where((v) => v.id > 0)
        .toList();
  }
}
