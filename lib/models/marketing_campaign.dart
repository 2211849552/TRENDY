class MarketingCampaign {
  final String id;
  final String name;
  final List<String> storeKeys;
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
    required this.statusKey,
    this.description,
    this.summary,
    this.badgeKey,
    required this.startAt,
    required this.endAt,
    this.imageUrl,
  });
}
