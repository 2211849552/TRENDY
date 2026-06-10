import '../../models/store_list_item.dart';
import 'api_client.dart';

class StoresApi {
  StoresApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// GET /api/stores?name=&type=&per_page=
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

  List<Map<String, dynamic>> _readList(dynamic raw) {
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }
}
