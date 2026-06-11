import '../../models/delivery_zone.dart';
import 'api_client.dart';

/// GET /api/zones — المناطق المدعومة (حسب api.md).
class ZonesApi {
  ZonesApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<DeliveryZone>> fetchZones() async {
    final json = await _client.getFromRoot('/zones', withAuth: false);
    final rows = json['data'];
    if (rows is! List) return const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(DeliveryZone.fromJson)
        .where((z) => z.id > 0 && z.name.isNotEmpty)
        .toList();
  }
}
