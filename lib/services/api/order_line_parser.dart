import '../../models/cart_item.dart';
import '../../models/product.dart';
import 'media_url.dart';

/// تحويل عنصر سلة/طلب من JSON إلى [CartItem] مع صور عبر [MediaUrl].
/// حقول الصورة المدعومة (api.md): `product_id`, `thumbnail`, `images[]`, `product.thumbnail`.
class OrderLineParser {
  OrderLineParser._();

  static CartItem? parse(
    Map<String, dynamic> json, {
    String storeName = '',
    int? storeId,
  }) {
    final name = productName(json);
    if (name.isEmpty) return null;

    final productId = productIdFrom(json);
    final imageUrl = imageUrlFrom(json, productId: productId);
    final price = _asDouble(json['price'] ?? json['unit_price']) ?? 0;
    final qty = _asInt(json['quantity']) ?? 1;
    final attrs = variantAttributes(json);

    final sku = '${json['sku'] ?? ''}'.trim();
    final code = sku.isNotEmpty
        ? sku
        : ('${json['variant_details'] ?? ''}'.trim().isEmpty
            ? null
            : '${json['variant_details']}'.trim());

    return CartItem(
      product: Product(
        id: productId,
        storeId: storeId,
        name: name,
        code: code,
        category: 'cat_all',
        price: price,
        rating: 0,
        imageUrl: imageUrl,
        storeName: storeName,
        isOutOfStock: json['is_available'] == false,
      ),
      selectedColor: attrs.$1,
      selectedSize: attrs.$2,
      quantity: qty,
      variantId: _asInt(json['variant_id']),
      apiItemId: _asInt(json['id']),
      availableStock: _asInt(json['available_stock']),
    );
  }

  static String productName(Map<String, dynamic> json) {
    final direct = '${json['product_name'] ?? ''}'.trim();
    if (direct.isNotEmpty) return direct;
    final product = json['product'];
    if (product is Map) return '${product['name'] ?? ''}'.trim();
    return '';
  }

  static int? productIdFrom(Map<String, dynamic> json) {
    final id = _asInt(json['product_id']);
    if (id != null && id > 0) return id;
    final product = json['product'];
    if (product is Map) return _asInt(product['id']);
    return null;
  }

  static String imageUrlFrom(Map<String, dynamic> json, {int? productId}) {
    final id = productId ?? productIdFrom(json);

    final product = json['product'];
    if (product is Map) {
      final nested = _imageFromProductMap(product, productId: id);
      if (nested.isNotEmpty) return nested;
    }

    for (final key in ['thumbnail', 'image', 'product_image', 'photo']) {
      final url = MediaUrl.productImage(json[key], productId: id);
      if (url.isNotEmpty) return url;
    }

    final images = MediaUrl.productImagesFromJson(json['images'], productId: id);
    if (images.isNotEmpty) return images.first;

    return '';
  }

  static String _imageFromProductMap(Map product, {int? productId}) {
    final id = productId ?? _asInt(product['id']);
    final images = MediaUrl.productImagesFromJson(product['images'], productId: id);
    if (images.isNotEmpty) return images.first;

    final thumb = MediaUrl.productThumbnail(product['thumbnail'], productId: id);
    if (thumb.isNotEmpty) return thumb;

    for (final key in ['image', 'product_image', 'photo']) {
      final url = MediaUrl.productImage(product[key], productId: id);
      if (url.isNotEmpty) return url;
    }
    return '';
  }

  static (String color, String size) variantAttributes(Map<String, dynamic> json) {
    var color = '${json['color'] ?? ''}'.trim();
    var size = '${json['size'] ?? ''}'.trim();

    final variant = json['variant'];
    if (variant is Map) {
      if (color.isEmpty) {
        color = '${variant['color'] ?? variant['color_value'] ?? ''}'.trim();
      }
      if (size.isEmpty) {
        size = '${variant['size'] ?? variant['size_value'] ?? ''}'.trim();
      }
    }

    if (color.isEmpty && size.isEmpty) {
      final details = '${json['variant_details'] ?? ''}'.trim();
      if (details.isNotEmpty) {
        final parts = details.split(RegExp(r'[/·|•,]'));
        if (parts.length >= 2) {
          color = parts[0].trim();
          size = parts[1].trim();
        } else if (parts.length == 1) {
          size = parts[0].trim();
        }
      }
    }

    return (color, size);
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
