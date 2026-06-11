import '../../models/cart_item.dart';
import 'api_client.dart';
import 'order_line_parser.dart';

class ApiCartSummary {
  const ApiCartSummary({
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
  });

  final double subtotal;
  final double deliveryFee;
  final double total;

  factory ApiCartSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ApiCartSummary(subtotal: 0, deliveryFee: 0, total: 0);
    }
    return ApiCartSummary(
      subtotal: _asDouble(json['subtotal']) ?? 0,
      deliveryFee: _asDouble(json['delivery_fee']) ?? 0,
      total: _asDouble(json['total']) ?? 0,
    );
  }

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }
}

class ApiCartContents {
  const ApiCartContents({required this.items, required this.summary});

  final List<CartItem> items;
  final ApiCartSummary summary;
}

/// GET/POST/PATCH/DELETE /api/cart — POST /api/cart/checkout
class CartApi {
  CartApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// GET /api/cart
  Future<ApiCartContents> fetchCart() async {
    final json = await _client.getFromRoot('/cart');
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      return const ApiCartContents(
        items: [],
        summary: ApiCartSummary(subtotal: 0, deliveryFee: 0, total: 0),
      );
    }

    final rawItems = data['items'];
    final items = <CartItem>[];
    if (rawItems is List) {
      for (final row in rawItems) {
        if (row is Map<String, dynamic>) {
          final item = _cartItemFromJson(row);
          if (item != null) items.add(item);
        }
      }
    }

    final summary = ApiCartSummary.fromJson(
      data['summary'] is Map<String, dynamic> ? data['summary'] as Map<String, dynamic> : null,
    );

    return ApiCartContents(items: items, summary: summary);
  }

  /// POST /api/cart — body: variant_id, quantity
  Future<void> addItem({required int variantId, required int quantity}) async {
    await _client.postFromRoot(
      '/cart',
      body: {'variant_id': variantId, 'quantity': quantity},
    );
  }

  /// PATCH /api/cart/{itemId}
  Future<void> updateItem({required int itemId, required int quantity}) async {
    await _client.patchFromRoot('/cart/$itemId', body: {'quantity': quantity});
  }

  /// DELETE /api/cart/{itemId}
  Future<void> removeItem(int itemId) async {
    await _client.deleteFromRoot('/cart/$itemId');
  }

  /// POST /api/cart/checkout
  Future<List<Map<String, dynamic>>> checkout({
    required String paymentType,
    required int shippingAddressId,
    required String googleMapUrl,
  }) async {
    final json = await _client.postFromRoot(
      '/cart/checkout',
      body: {
        'payment_type': paymentType,
        'shipping_address_id': shippingAddressId,
        'google_map_url': googleMapUrl,
      },
    );
    final data = json['data'];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    if (data is Map<String, dynamic>) return [data];
    return const [];
  }

  CartItem? _cartItemFromJson(Map<String, dynamic> json) {
    final itemId = _asInt(json['id']);
    if (itemId == null || itemId <= 0) return null;

    final item = OrderLineParser.parse(json);
    if (item == null) return null;

    return CartItem(
      product: item.product,
      selectedColor: item.selectedColor,
      selectedSize: item.selectedSize,
      quantity: item.quantity,
      variantId: item.variantId,
      apiItemId: itemId,
      availableStock: item.availableStock ?? _asInt(json['available_stock']),
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }
}
