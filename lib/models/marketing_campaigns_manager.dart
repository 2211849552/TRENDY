import 'package:flutter/foundation.dart';

import '../data/campaign_visuals.dart';
import '../services/api/campaigns_api.dart';
import 'marketing_campaign.dart';

class MarketingCampaignsManager extends ChangeNotifier {
  MarketingCampaignsManager._();
  static final MarketingCampaignsManager _instance = MarketingCampaignsManager._();
  factory MarketingCampaignsManager() => _instance;

  final CampaignsApi _api = CampaignsApi();
  bool _useApi = false;
  bool _isLoading = false;

  final List<MarketingCampaign> _fallbackCampaigns = [
    MarketingCampaign(
      id: 'cmp_001',
      name: 'عروض الجمعة البيضاء',
      storeKeys: ['store_elegance', 'store_luxury', 'store_gentle'],
      statusKey: 'campaign_status_active',
      badgeKey: 'campaign_badge_white_friday',
      summary: 'خصومات ضخمة على تشكيلة مختارة من جميع المتاجر',
      description:
          'عروض الجمعة البيضاء: خصومات حصرية على منتجات مختارة في متاجر التطبيق المشاركة. العرض لفترة محدودة.',
      startAt: DateTime(2026, 5, 1),
      endAt: DateTime(2026, 6, 30),
      imageUrl: CampaignVisuals.forCampaign('cmp_001').imageUrl,
    ),
    MarketingCampaign(
      id: 'cmp_002',
      name: 'تخفيض 15% على أول طلب لك',
      storeKeys: ['store_gentle', 'store_fashion', 'store_top'],
      statusKey: 'campaign_status_active',
      badgeKey: 'campaign_badge_first_order',
      summary: 'خصم 15% على أول طلب لك من المتاجر المشاركة',
      description:
          'سجّل طلبك الأول واحصل على خصم 15% على مشترياتك من المتاجر المشاركة في الحملة (حسب الشروط).',
      startAt: DateTime(2026, 5, 1),
      endAt: DateTime(2026, 7, 31),
      imageUrl: CampaignVisuals.forCampaign('cmp_002').imageUrl,
    ),
    MarketingCampaign(
      id: 'cmp_003',
      name: 'تخفيضات نهاية الموسم',
      storeKeys: ['store_kids', 'store_elegance'],
      statusKey: 'campaign_status_active',
      badgeKey: 'campaign_badge_end_season',
      summary: 'تخفيضات تصل إلى 70% على منتجات مختارة',
      description:
          'تخفيضات نهاية الموسم: فرصة لتوفير الكثير على ملابس مختارة من المتاجر المشاركة قبل انتهاء المخزون.',
      startAt: DateTime(2026, 4, 15),
      endAt: DateTime(2026, 6, 30),
      imageUrl: CampaignVisuals.forCampaign('cmp_003').imageUrl,
    ),
  ];

  List<MarketingCampaign> _apiCampaigns = [];

  bool get isLoading => _isLoading;

  List<MarketingCampaign> get campaigns =>
      _useApi ? _apiCampaigns : _fallbackCampaigns;

  List<MarketingCampaign> get homeFeatured {
    final source = campaigns
        .where((c) => c.statusKey == 'campaign_status_active')
        .toList();
    source.sort((a, b) => b.startAt.compareTo(a.startAt));
    return source.take(3).toList();
  }

  Future<void> loadFromApi({int limit = 6}) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      final items = await _api.fetchActiveCampaigns(limit: limit);
      if (items.isNotEmpty) {
        _apiCampaigns = items;
        _useApi = true;
      }
    } catch (_) {
      // نُبقي الحملات الاحتياطية عند فشل الاتصال.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
