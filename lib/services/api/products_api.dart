import '../../models/product_search_item.dart';
import 'api_client.dart';

class ProductsApi {
  ProductsApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// GET /api/products/search?q=&per_page=
  Future<List<ProductSearchItem>> searchProducts({
    required String query,
    int perPage = 20,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    final json = await _client.getFromRoot(
      '/products/search',
      query: {
        'q': q,
        'per_page': '$perPage',
      },
      withAuth: false,
    );

    final rows = _readList(json['data']);
    return rows.map(ProductSearchItem.fromJson).where((p) => p.id > 0).toList();
  }

  List<Map<String, dynamic>> _readList(dynamic raw) {
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }
}
