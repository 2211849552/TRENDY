import '../../models/store_list_item.dart';
import 'api_client.dart';
import 'media_url.dart';

class StoresApi {
  StoresApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// GET /api/stores — حقل `logo` حسب api.md
  Future<List<StoreListItem>> fetchStores({
    String? name,
    String? type,
    int perPage = 50,
  }) async {
    final query = <String, String>{
      'per_page': '$perPage',
    };
    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) {
      query['name'] = trimmedName;
    }
    if (type != null && type.isNotEmpty) {
      query['type'] = type;
    }

    final json = await _client.getFromRoot('/stores', query: query, withAuth: false);
    final rows = _readList(json['data']);
    return rows.map(StoreListItem.fromJson).where((s) => s.id > 0).toList();
  }

  /// تحميل صور إضافية للمتاجر بدون `logo` (لا يؤخر ظهور القائمة).
  Future<List<StoreListItem>> enrichMissingLogos(List<StoreListItem> stores) async {
    final updated = await Future.wait(stores.map(_enrichLogoIfMissing));
    return updated;
  }

  /// GET /api/stores/{id}
  Future<StoreListItem> fetchStore(int id) async {
    final json = await _client.getFromRoot('/stores/$id', withAuth: false);
    final data = json['data'];
    final store = data is Map<String, dynamic>
        ? StoreListItem.fromJson(data)
        : StoreListItem.fromJson(json);
    return _enrichLogoIfMissing(store);
  }

  /// إذا `logo` فارغ: GET /api/stores/{id}/products — صورة أول منتج `thumbnail`
  Future<StoreListItem> _enrichLogoIfMissing(StoreListItem store) async {
    if (store.imageUrl.isNotEmpty) return store;
    try {
      final json = await _client.getFromRoot(
        '/stores/${store.id}/products',
        query: {'per_page': '1'},
        withAuth: false,
      );
      final rows = _readList(json['data']);
      if (rows.isEmpty) return store;
      final thumb = MediaUrl.productThumbnail(rows.first['thumbnail']);
      if (thumb.isEmpty) return store;
      return store.copyWith(imageUrl: thumb);
    } catch (_) {
      return store;
    }
  }

  List<Map<String, dynamic>> _readList(dynamic raw) {
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }
}
