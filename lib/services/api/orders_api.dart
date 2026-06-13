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
    return _readOrderRows(json['data']);
  }

  /// يدعم `{ data: [...] }` و `{ data: { data: [...] } }` كما في بعض استجابات Laravel.
  static List<Map<String, dynamic>> _readOrderRows(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final nested = raw['data'];
      if (nested is List) {
        return nested.whereType<Map<String, dynamic>>().toList();
      }
    }
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList();
    }
    return const [];
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

  /// GET /api/orders/{id} — تحديث تفاصيل طلب واحد (OTP، الحالة، …).
  Future<Order> refreshOrderDetails(Order order) async {
    final apiId = order.apiId;
    if (apiId == null || apiId <= 0) return order;
    final fresh = await fetchOrderDetails(apiId);
    return fresh ?? order;
  }

  /// POST /api/orders/{id}/confirm-delivery — تأكيد الاستلام برمز التحقق (انظر api.md [16.7]).
  Future<Order> confirmDelivery(int orderId, {required String otp}) async {
    final code = otp.trim();
    if (code.length != 6) {
      throw ApiException('يرجى إدخال رمز تحقق مكوّن من 6 أرقام');
    }

    final json = await _client.postFromRoot(
      CustomerApiPaths.orderConfirmDelivery(orderId),
      body: {'otp': code},
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
    final otpRaw = json['otp_code'];
    final otpCode = otpRaw == null ? null : '$otpRaw'.trim();

    return Order(
      id: '${json['order_number'] ?? json['id'] ?? ''}',
      apiId: _asInt(json['id']),
      date: DateTime.tryParse('${json['created_at'] ?? ''}') ?? DateTime.now(),
      items: items,
      totalPrice: _asDouble(json['total_amount']) ?? 0,
      deliveryFee: _asDouble(json['delivery_fee']) ?? 0,
      status: _mapStatus('${json['status'] ?? ''}'),
      storeName: storeName,
      storeId: storeId,
      paymentMethod: mappedPayment,
      otpCode: otpCode != null && otpCode.isNotEmpty ? otpCode : null,
      driverName: _nullableString(json['driver_name']),
      deliveredAt: DateTime.tryParse('${json['delivered_at'] ?? ''}'),
    );
  }

  static String? _nullableString(dynamic value) {
    final text = '$value'.trim();
    return text.isEmpty ? null : text;
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
