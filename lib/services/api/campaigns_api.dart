import '../../config/api_config.dart';
import '../../models/marketing_campaign.dart';
import 'api_client.dart';

class CampaignsApi {
  CampaignsApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// GET /api/campaigns
  Future<List<MarketingCampaign>> fetchActiveCampaigns({int limit = 6}) async {
    final json = await _client.getFromRoot(
      '/campaigns',
      query: {'per_page': '$limit'},
      withAuth: false,
    );
    final rows = _readList(json['data']);
    return rows.map(_fromJson).where((c) => c.id.isNotEmpty).toList();
  }

  MarketingCampaign _fromJson(Map<String, dynamic> json) {
    final start = DateTime.tryParse('${json['start_date'] ?? ''}') ?? DateTime.now();
    final end = DateTime.tryParse('${json['end_date'] ?? ''}') ?? start.add(const Duration(days: 30));
    final stores = _readStores(json['stores']);

    return MarketingCampaign(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}'.trim(),
      storeKeys: stores.map((s) => s.navigationKey).toList(),
      stores: stores,
      statusKey: 'campaign_status_active',
      summary: '${json['description'] ?? ''}'.trim(),
      description: '${json['description'] ?? ''}'.trim(),
      badgeKey: 'campaign_badge_discount',
      startAt: start,
      endAt: end,
      imageUrl: '${json['banner_image'] ?? ''}'.trim().isEmpty
          ? null
          : ApiConfig.resolveMediaUrl('${json['banner_image']}'.trim()),
    );
  }

  List<CampaignStoreRef> _readStores(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map((s) {
          final id = int.tryParse('${s['id']}') ?? 0;
          final discount = '${s['discount_percentage'] ?? ''}'.trim();
          return CampaignStoreRef(
            id: id,
            name: '${s['name'] ?? ''}'.trim(),
            slug: '${s['slug'] ?? ''}'.trim(),
            logoUrl: ApiConfig.resolveMediaUrl('${s['logo'] ?? ''}'),
            discountPercentage: discount.isEmpty ? null : discount,
          );
        })
        .where((s) => s.id > 0)
        .toList();
  }

  List<Map<String, dynamic>> _readList(dynamic raw) {
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }
}
