import '../../models/cart_item.dart';
import '../../models/order.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'order_line_parser.dart';

/// GET /api/orders — GET /api/orders/{id}
class OrdersApi {
  OrdersApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// GET /api/orders
  Future<List<Order>> fetchOrders() async {
    final json = await _client.getFromRoot('/orders');
    final rows = json['data'];
    if (rows is! List) return const [];
    return rows.whereType<Map<String, dynamic>>().map(_orderFromJson).toList();
  }

  /// GET /api/orders/{id}
  Future<Order?> fetchOrderDetails(int orderId) async {
    final json = await _client.getFromRoot('/orders/$orderId');
    final data = json['data'];
    if (data is Map<String, dynamic>) return _orderFromJson(data);
    return null;
  }

  /// POST /api/orders/{id}/confirm-delivery — تأكيد الاستلام (سائق/متجر؛ يُستخدم عند توفر الصلاحية).
  Future<Order> confirmDelivery(int orderId, {String? otp}) async {
    final json = await _client.postFromRoot(
      '/orders/$orderId/confirm-delivery',
      body: otp != null && otp.length == 6 ? {'otp': otp} : null,
    );
    final data = json['data'];
    if (data is Map<String, dynamic>) return _orderFromJson(data);
    throw ApiException('تعذر تأكيد استلام الطلب');
  }

  Order _orderFromJson(Map<String, dynamic> json) {
    final storeName = '${json['store_name'] ?? ''}'.trim();
    final storeId = _asInt(json['store_id']);
    final items = <CartItem>[];
    final rawItems = json['items'];
    if (rawItems is List) {
      for (final row in rawItems) {
        if (row is Map<String, dynamic>) {
          final item = OrderLineParser.parse(
            row,
            storeName: storeName,
            storeId: storeId,
          );
          if (item != null) items.add(item);
        }
      }
    }

    final paymentMethod = '${json['payment_method'] ?? ''}'.trim();
    final mappedPayment = paymentMethod == 'wallet' ? 'payment_wallet' : 'payment_cash';

    return Order(
      id: '${json['order_number'] ?? json['id'] ?? ''}',
      apiId: _asInt(json['id']),
      date: DateTime.tryParse('${json['created_at'] ?? ''}') ?? DateTime.now(),
      items: items,
      totalPrice: _asDouble(json['total_amount']) ?? 0,
      status: _mapStatus('${json['status'] ?? ''}'),
      storeName: storeName,
      storeId: storeId,
      paymentMethod: mappedPayment,
    );
  }

  String _mapStatus(String apiStatus) {
    switch (apiStatus.toLowerCase()) {
      case 'pending':
      case 'pending_admin':
      case 'processing':
        return 'status_pending';
      case 'ready':
      case 'prepared':
      case 'shipped':
      case 'out_for_delivery':
        return 'status_ready';
      case 'delivered':
      case 'completed':
        return 'status_delivered';
      case 'cancelled':
      case 'canceled':
      case 'returned':
        return 'status_cancelled';
      default:
        return 'status_pending';
    }
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
