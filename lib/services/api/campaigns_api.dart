import '../../models/marketing_campaign.dart';
import 'api_client.dart';
import 'media_url.dart';

class CampaignsApi {
  CampaignsApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// GET /api/campaigns — قائمة الحملات النشطة مع المتاجر المشتركة (حسب api.md).
  Future<List<MarketingCampaign>> fetchActiveCampaigns({int limit = 20}) async {
    final json = await _client.getFromRoot(
      '/campaigns',
      query: {'per_page': '$limit'},
      withAuth: false,
    );
    final rows = _readList(json['data']);
    return rows.map(_fromJson).where((c) => c.id.isNotEmpty).toList();
  }

  /// GET /api/campaigns/{id} — تفاصيل حملة نشطة مع المتاجر المشتركة.
  Future<MarketingCampaign?> fetchCampaignById(int id) async {
    if (id <= 0) return null;
    final json = await _client.getFromRoot('/campaigns/$id', withAuth: false);
    final data = json['data'];
    if (data is! Map<String, dynamic>) return null;
    final campaign = _fromJson(data);
    return campaign.id.isEmpty ? null : campaign;
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
      statusKey: _statusKeyFromApi('${json['status'] ?? ''}'),
      summary: '${json['description'] ?? ''}'.trim(),
      description: '${json['description'] ?? ''}'.trim(),
      badgeKey: 'campaign_badge_discount',
      startAt: start,
      endAt: end,
      imageUrl: MediaUrl.campaignBanner(json['banner_image']),
    );
  }

  static String _statusKeyFromApi(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'campaign_status_active';
      case 'paused':
        return 'campaign_status_paused';
      case 'finished':
      case 'ended':
        return 'campaign_status_ended';
      case 'scheduled':
        return 'campaign_status_planned';
      case 'draft':
        return 'campaign_status_draft';
      default:
        return 'campaign_status_active';
    }
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
            logoUrl: MediaUrl.storeLogo(s['logo']),
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
