import 'package:flutter/foundation.dart';

import '../data/campaign_visuals.dart';
import 'marketing_campaign.dart';

class MarketingCampaignsManager extends ChangeNotifier {
  MarketingCampaignsManager._();
  static final MarketingCampaignsManager _instance = MarketingCampaignsManager._();
  factory MarketingCampaignsManager() => _instance;

  final List<MarketingCampaign> _campaigns = [
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
    MarketingCampaign(
      id: 'cmp_004',
      name: 'بضاعة جديدة وصلت',
      storeKeys: ['store_fashion'],
      statusKey: 'campaign_status_planned',
      badgeKey: 'campaign_badge_new',
      summary: 'تشكيلة رجالية جديدة قريباً',
      description: 'بوتيك الموضة: تشكيلة رجالية جديدة قريباً. تابعونا للتفاصيل.',
      startAt: DateTime(2026, 6, 1),
      endAt: DateTime(2026, 7, 15),
      imageUrl: CampaignVisuals.forCampaign('cmp_004').imageUrl,
    ),
    MarketingCampaign(
      id: 'cmp_005',
      name: 'عرض خاص: حقيبة + إكسسوار',
      storeKeys: ['store_luxury'],
      statusKey: 'campaign_status_paused',
      badgeKey: 'campaign_badge_gift',
      summary: 'حقيبة يد + إكسسوار مجاناً',
      description: 'متجر الفخامة: عند شراء حقيبة يد فاخرة تحصل على إكسسوار مجاناً. العرض متوقف مؤقتاً.',
      startAt: DateTime(2026, 4, 1),
      endAt: DateTime(2026, 5, 15),
      imageUrl: CampaignVisuals.forCampaign('cmp_005').imageUrl,
    ),
    MarketingCampaign(
      id: 'cmp_006',
      name: 'تخفيضات محدودة على الأحذية',
      storeKeys: ['store_top'],
      statusKey: 'campaign_status_ended',
      badgeKey: 'campaign_badge_discount',
      summary: 'انتهى العرض',
      description: 'توب فاشن: خصم على الأحذية. انتهى العرض، انتظروا عروضاً جديدة.',
      startAt: DateTime(2026, 2, 10),
      endAt: DateTime(2026, 2, 20),
      imageUrl: CampaignVisuals.forCampaign('cmp_006').imageUrl,
    ),
  ];

  List<MarketingCampaign> get campaigns => List.unmodifiable(_campaigns);

  List<MarketingCampaign> get homeFeatured {
    final active = _campaigns.where((c) => c.statusKey == 'campaign_status_active').toList();
    active.sort((a, b) => b.startAt.compareTo(a.startAt));
    return active.take(3).toList();
  }
}
