import '../config/api_config.dart';

class ProductSearchItem {
  const ProductSearchItem({
    required this.id,
    required this.name,
    required this.price,
    required this.thumbnail,
    required this.storeName,
    this.hasDiscount = false,
  });

  final int id;
  final String name;
  final double price;
  final String thumbnail;
  final String storeName;
  final bool hasDiscount;

  factory ProductSearchItem.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    var storeName = '';
    if (category is Map) {
      storeName = '${category['name'] ?? ''}'.trim();
    }

    return ProductSearchItem(
      id: _asInt(json['id']) ?? 0,
      name: '${json['name'] ?? ''}'.trim(),
      price: _asDouble(json['discounted_price'] ?? json['base_price']) ?? 0,
      thumbnail: ApiConfig.resolveMediaUrl('${json['thumbnail'] ?? ''}'),
      storeName: storeName,
      hasDiscount: json['has_discount'] == true,
    );
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
}
