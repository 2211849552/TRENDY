import 'package:flutter/foundation.dart';

import 'marketing_campaign.dart';

class MarketingCampaignsManager extends ChangeNotifier {
  static final MarketingCampaignsManager _instance = MarketingCampaignsManager._();
  factory MarketingCampaignsManager() => _instance;
  MarketingCampaignsManager._();

  final List<MarketingCampaign> _campaigns = [
    MarketingCampaign(
      id: 'cmp_001',
      name: 'بضاعة جديدة وصلت',
      storeKey: 'store_elegance',
      statusKey: 'campaign_status_active',
      description:
          'متجر الأناقة يعلن عن وصول قطع جديدة: فساتين ميدي، بلوزات ساتان، وشنط توت. الكميات محدودة.',
      startAt: DateTime(2026, 3, 20),
      endAt: DateTime(2026, 4, 25),
      imageUrl: 'https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=1200&q=80',
    ),
    MarketingCampaign(
      id: 'cmp_002',
      name: 'اشترِ قطعة وخذ قطعة مجاناً',
      storeKey: 'store_fashion',
      statusKey: 'campaign_status_planned',
      description:
          'بوتيك الموضة: عند شراء تيشيرت/هودي من التشكيلة الجديدة تحصل على تيشيرت Basic مجاناً (حسب التوفر).',
      startAt: DateTime(2026, 4, 18),
      endAt: DateTime(2026, 5, 2),
      imageUrl: 'https://images.unsplash.com/photo-1520975916090-3105956dac38?auto=format&fit=crop&w=1200&q=80',
    ),
    MarketingCampaign(
      id: 'cmp_003',
      name: 'تخفيض على قطع جديدة',
      storeKey: 'store_gentle',
      statusKey: 'campaign_status_active',
      description:
          'الرجل الأنيق: خصم 20% على تشكيلة القمصان الأوكسفورد واللوفر الجلد الجديدة هذا الأسبوع.',
      startAt: DateTime(2026, 4, 10),
      endAt: DateTime(2026, 4, 17),
      imageUrl: 'https://images.unsplash.com/photo-1521336575822-6da63fb45455?auto=format&fit=crop&w=1200&q=80',
    ),
    MarketingCampaign(
      id: 'cmp_004',
      name: 'عرض خاص: حقيبة + إكسسوار',
      storeKey: 'store_luxury',
      statusKey: 'campaign_status_paused',
      description:
          'متجر الفخامة: عند شراء حقيبة يد فاخرة تحصل على سوار/إكسسوار مجاناً. العرض متوقف مؤقتاً لحين تجديد المخزون.',
      startAt: DateTime(2026, 4, 1),
      endAt: DateTime(2026, 5, 15),
      imageUrl: 'https://images.unsplash.com/photo-1490114538077-0a7f8cb49891?auto=format&fit=crop&w=1200&q=80',
    ),
    MarketingCampaign(
      id: 'cmp_005',
      name: 'تجهيزات أطفال جديدة',
      storeKey: 'store_kids',
      statusKey: 'campaign_status_draft',
      description:
          'عالم الأطفال: وصول حقائب جديدة + أحذية أطفال مريحة. (مسودة قبل الإطلاق الرسمي).',
      startAt: DateTime(2026, 4, 28),
      endAt: DateTime(2026, 5, 25),
      imageUrl: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&w=1200&q=80',
    ),
    MarketingCampaign(
      id: 'cmp_006',
      name: 'تخفيضات محدودة على الأحذية',
      storeKey: 'store_top',
      statusKey: 'campaign_status_ended',
      description:
          'توب فاشن: خصم على سنيكرز تشنكي وبوت شتوي. انتهى العرض، انتظروا عروض جديدة قريباً.',
      startAt: DateTime(2026, 2, 10),
      endAt: DateTime(2026, 2, 20),
      imageUrl: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&w=1200&q=80',
    ),
  ];

  List<MarketingCampaign> get campaigns => List.unmodifiable(_campaigns);
}

