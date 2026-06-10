/// متجر مشترك في حملة إعلانية (من API).
class CampaignStoreRef {
  final int id;
  final String name;
  final String slug;
  final String logoUrl;
  final String? discountPercentage;

  const CampaignStoreRef({
    required this.id,
    required this.name,
    required this.slug,
    required this.logoUrl,
    this.discountPercentage,
  });

  /// المفتاح المستخدم للتنقل لصفحة المتجر (يطابق StoreListItem.navigationKey).
  String get navigationKey => slug.isNotEmpty ? slug : 'store_$id';
}

class MarketingCampaign {
  final String id;
  final String name;
  final List<String> storeKeys;
  final List<CampaignStoreRef> stores;
  final String statusKey;
  final String? description;
  final String? summary;
  final String? badgeKey;
  final DateTime startAt;
  final DateTime endAt;
  final String? imageUrl;

  String get storeKey => storeKeys.first;

  const MarketingCampaign({
    required this.id,
    required this.name,
    required this.storeKeys,
    this.stores = const [],
    required this.statusKey,
    this.description,
    this.summary,
    this.badgeKey,
    required this.startAt,
    required this.endAt,
    this.imageUrl,
  });
}
