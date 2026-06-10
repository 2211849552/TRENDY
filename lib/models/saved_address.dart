/// عنوان شحن محفوظ — محلي أو من API.
class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.label,
    required this.streetLine,
    required this.city,
    this.description,
    required this.lat,
    required this.lng,
    this.zoneId = defaultZoneId,
    this.phone,
    this.apiId,
  });

  static const defaultZoneId = 3;

  /// معرف محلي أو نصي — للعرض والاختيار في الواجهة.
  final String id;

  /// معرف العنوان في الخادم (إن وُجد).
  final int? apiId;

  final String label;
  final String streetLine;
  final String city;
  final String? description;
  final double lat;
  final double lng;
  final int zoneId;
  final String? phone;

  SavedAddress copyWith({
    String? label,
    String? streetLine,
    String? city,
    String? description,
    double? lat,
    double? lng,
    int? zoneId,
    String? phone,
    int? apiId,
  }) {
    return SavedAddress(
      id: id,
      apiId: apiId ?? this.apiId,
      label: label ?? this.label,
      streetLine: streetLine ?? this.streetLine,
      city: city ?? this.city,
      description: description ?? this.description,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      zoneId: zoneId ?? this.zoneId,
      phone: phone ?? this.phone,
    );
  }

  factory SavedAddress.fromApiJson(Map<String, dynamic> json) {
    final apiId = int.tryParse('${json['id'] ?? ''}');
    final coords = _parseCoordsFromMapUrl('${json['google_map_url'] ?? ''}');

    return SavedAddress(
      id: apiId != null ? 'addr_$apiId' : '',
      apiId: apiId,
      label: _firstNonEmpty([
        json['address_line_1']?.toString(),
      ]) ?? '',
      streetLine: _firstNonEmpty([
        json['address_line_2']?.toString(),
        json['address_line_1']?.toString(),
      ]) ?? '',
      city: '${json['city'] ?? ''}'.trim(),
      description: null,
      lat: coords?.$1 ?? 32.8872,
      lng: coords?.$2 ?? 13.1913,
      zoneId: int.tryParse('${json['zone_id'] ?? defaultZoneId}') ?? defaultZoneId,
      phone: json['phone']?.toString(),
    );
  }

  Map<String, dynamic> toApiBody({String? fallbackPhone}) {
    final line2Parts = <String>[];
    if (streetLine.trim().isNotEmpty) line2Parts.add(streetLine.trim());
    if (description != null && description!.trim().isNotEmpty) {
      line2Parts.add(description!.trim());
    }

    final body = <String, dynamic>{
      'address_line_1': label.trim(),
      'city': city.trim(),
      'zone_id': zoneId,
      'google_map_url': googleMapUrl,
    };
    if (line2Parts.isNotEmpty) {
      body['address_line_2'] = line2Parts.join(' — ');
    }
    final resolvedPhone = (phone ?? fallbackPhone)?.trim();
    if (resolvedPhone != null && resolvedPhone.isNotEmpty) {
      body['phone'] = resolvedPhone;
    }
    return body;
  }

  String get googleMapUrl =>
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

  static (double, double)? _parseCoordsFromMapUrl(String url) {
    final match = RegExp(r'query=([-\d.]+),([-\d.]+)').firstMatch(url);
    if (match == null) return null;
    final lat = double.tryParse(match.group(1)!);
    final lng = double.tryParse(match.group(2)!);
    if (lat == null || lng == null) return null;
    return (lat, lng);
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }
}
