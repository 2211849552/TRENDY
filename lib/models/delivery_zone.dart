/// منطقة توصيل محددة من الإدارة — من GET /api/zones.
class DeliveryZone {
  const DeliveryZone({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory DeliveryZone.fromJson(Map<String, dynamic> json) {
    return DeliveryZone(
      id: int.tryParse('${json['id'] ?? ''}') ?? 0,
      name: '${json['name'] ?? ''}'.trim(),
    );
  }
}
