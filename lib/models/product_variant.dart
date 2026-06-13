class ProductVariantOption {
  const ProductVariantOption({
    required this.id,
    required this.price,
    required this.originalPrice,
    required this.stock,
    required this.attributes,
  });

  final int id;
  final double price;
  final double originalPrice;
  final int stock;
  final Map<String, String> attributes;

  String? attr(String key) {
    final lower = key.toLowerCase();
    for (final entry in attributes.entries) {
      if (entry.key.toLowerCase().contains(lower)) return entry.value;
    }
    return null;
  }

  String? get colorValue {
    for (final entry in attributes.entries) {
      if (_isColorKey(entry.key.toLowerCase())) return entry.value;
    }
    return attr('لون') ?? attr('color');
  }

  String? get sizeValue {
    for (final entry in attributes.entries) {
      if (_isSizeKey(entry.key.toLowerCase())) return entry.value;
    }
    final direct = attr('مقاس') ?? attr('size');
    if (direct != null) return direct;
    for (final entry in attributes.entries) {
      if (_looksLikeSizeValue(entry.value)) return entry.value;
    }
    return null;
  }

  static bool _looksLikeSizeValue(String value) {
    final v = value.trim().toUpperCase();
    const known = ['XXS', 'XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL', '2XL', '3XL', '4XL'];
    return known.contains(v) || RegExp(r'^\d{1,2}$').hasMatch(v);
  }

  static bool _isColorKey(String name) =>
      name.contains('اللون') ||
      name.contains('لون') ||
      name.contains('color') ||
      name.contains('colour');

  static bool _isSizeKey(String name) =>
      name.contains('مقاس') ||
      name.contains('قاس') ||
      name.contains('size') ||
      name.contains('taille') ||
      name.contains('المقاس') ||
      name.contains('حجم') ||
      name.contains('الحجم');

  static bool isColorAttributeName(String name) => _isColorKey(name.toLowerCase());

  static bool isSizeAttributeName(String name) => _isSizeKey(name.toLowerCase());

  factory ProductVariantOption.fromJson(Map<String, dynamic> json) {
    final attrs = <String, String>{};
    final rawValues = json['attribute_values'];
    if (rawValues is List) {
      for (final item in rawValues) {
        if (item is! Map) continue;
        final attribute = item['attribute'];
        final name = attribute is Map
            ? '${attribute['name'] ?? ''}'.trim()
            : '${item['attribute_name'] ?? ''}'.trim();
        final value = '${item['value'] ?? ''}'.trim();
        if (name.isNotEmpty && value.isNotEmpty) {
          attrs[name] = value;
        }
      }
    }

    final price = _asDouble(json['discounted_price'] ?? json['price']) ?? 0;
    final original = _asDouble(json['original_price'] ?? price) ?? price;

    return ProductVariantOption(
      id: _asInt(json['id']) ?? 0,
      price: price,
      originalPrice: original,
      stock: _asInt(json['total_quantity'] ?? json['quantity']) ?? 0,
      attributes: attrs,
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
