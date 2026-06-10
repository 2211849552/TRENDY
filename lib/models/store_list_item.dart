import '../config/api_config.dart';
import '../services/store_location.dart';

class StoreListItem {
  const StoreListItem({
    required this.id,
    required this.displayName,
    required this.slug,
    required this.imageUrl,
    required this.isElectronic,
    required this.rating,
    required this.categoryLabel,
    required this.deliveryFee,
    this.discount,
    this.location,
    this.displayDistanceKm,
    this.description,
    this.googleMapUrl,
  });

  final int id;
  final String displayName;
  final String slug;
  final String imageUrl;
  final bool isElectronic;
  final double rating;
  final String categoryLabel;
  final double deliveryFee;
  final String? discount;
  final StoreLocation? location;
  final double? displayDistanceKm;
  final String? description;
  final String? googleMapUrl;

  String get navigationKey => slug.isNotEmpty ? slug : 'store_$id';

  factory StoreListItem.fromJson(Map<String, dynamic> json) {
    final type = '${json['type'] ?? 'local'}'.toLowerCase();
    final deliveryFee = _readDeliveryFee(json['delivery_prices']);

    return StoreListItem(
      id: _asInt(json['id']) ?? 0,
      displayName: '${json['name'] ?? ''}'.trim(),
      slug: '${json['slug'] ?? ''}'.trim(),
      imageUrl: ApiConfig.resolveMediaUrl('${json['logo'] ?? ''}'),
      isElectronic: type == 'electronic',
      rating: _asDouble(json['average_rating']) ?? 4.5,
      categoryLabel: _firstNonEmpty([
        json['entity_type']?.toString(),
        json['zone_name']?.toString(),
        json['description']?.toString(),
      ]) ?? '',
      deliveryFee: deliveryFee,
      description: json['description']?.toString(),
      googleMapUrl: _firstNonEmpty([json['google_map_url']?.toString()]),
    );
  }

  /// تحويل لصيغة الكتالوج المحلي القديم (للتوافق مع الشاشات الحالية).
  Map<String, dynamic> toLegacyMap() {
    return {
      'id': id,
      'name': navigationKey,
      'displayName': displayName,
      'category': categoryLabel,
      'rating': rating,
      'isElectronic': isElectronic,
      'location': location,
      'displayDistanceKm': displayDistanceKm,
      'deliveryFee': deliveryFee,
      'imageUrl': imageUrl,
      'discount': discount,
      'description': description,
      'googleMapUrl': googleMapUrl,
    };
  }

  static double _readDeliveryFee(dynamic raw) {
    if (raw is Map && raw.isNotEmpty) {
      for (final value in raw.values) {
        final fee = _asDouble(value);
        if (fee != null) return fee;
      }
    }
    return 5.0;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}
