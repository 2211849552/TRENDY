import '../../models/cart_item.dart';
import '../../models/order.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'customer_api_paths.dart';
import 'order_line_parser.dart';

/// طلبات الزبون — انظر [CustomerApiPaths] و `lib/api.md` قسم [16].
class OrdersApi {
  OrdersApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// GET /api/orders — صفوف JSON خام (للشكاوى وغيرها).
  Future<List<Map<String, dynamic>>> fetchOrdersRaw({
    String? search,
    String? status,
    int page = 1,
    int perPage = 50,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
    };
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (status != null && status.trim().isNotEmpty) {
      query['status'] = status.trim();
    }

    final json = await _client.getFromRoot(
      CustomerApiPaths.orders,
      query: query,
    );
    final rows = json['data'];
    if (rows is! List) return const [];
    return rows.whereType<Map<String, dynamic>>().toList();
  }

  /// GET /api/orders — قائمة طلبات الزبون (بحث/فلترة اختيارية).
  Future<List<Order>> fetchOrders({
    String? search,
    String? status,
    int page = 1,
    int perPage = 50,
  }) async {
    final rows = await fetchOrdersRaw(
      search: search,
      status: status,
      page: page,
      perPage: perPage,
    );
    return rows.map(_orderFromJson).toList();
  }

  /// GET /api/orders/{id}
  Future<Order?> fetchOrderDetails(int orderId) async {
    final json = await _client.getFromRoot(CustomerApiPaths.order(orderId));
    final data = json['data'];
    if (data is Map<String, dynamic>) return _orderFromJson(data);
    return null;
  }

  /// POST /api/orders/{id}/confirm-delivery — تم الاستلام (انظر api.md [16.7]).
  Future<Order> confirmDelivery(int orderId, {String? otp}) async {
    final json = await _client.postFromRoot(
      CustomerApiPaths.orderConfirmDelivery(orderId),
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
