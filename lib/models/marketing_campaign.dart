class MarketingCampaign {
  final String id;
  final String name;
  final String storeKey; // one of app stores keys (e.g. store_elegance)
  final String statusKey; // e.g. campaign_status_active
  final String? description;
  final DateTime startAt;
  final DateTime endAt;
  final String? imageUrl;

  const MarketingCampaign({
    required this.id,
    required this.name,
    required this.storeKey,
    required this.statusKey,
    this.description,
    required this.startAt,
    required this.endAt,
    this.imageUrl,
  });
}

