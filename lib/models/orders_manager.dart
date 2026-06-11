import 'package:flutter/material.dart';

import '../services/api/api_exception.dart';
import '../services/api/orders_api.dart';
import '../services/product_line_enricher.dart';
import 'cart_item.dart';
import 'cart_manager.dart';
import 'notification_item.dart';
import 'notification_manager.dart';
import 'order.dart';

class OrdersManager extends ChangeNotifier {
  static final OrdersManager _instance = OrdersManager._internal();
  factory OrdersManager() => _instance;
  OrdersManager._internal();

  final OrdersApi _api = OrdersApi();
  final ProductLineEnricher _enricher = ProductLineEnricher();
  final List<Order> _orders = [];
  final Map<String, String> _lineImageCache = {};
  bool _loading = false;
  String? _error;

  String _lineCacheKey(String orderId, String productName) =>
      '$orderId::${productName.trim()}';

  void _rememberLineImages(Order order) {
    for (final line in order.items) {
      final url = line.product.imageUrl.trim();
      final name = line.product.name.trim();
      if (url.isEmpty || name.isEmpty) continue;
      _lineImageCache[_lineCacheKey(order.id, name)] = url;
      _lineImageCache['name::$name'] = url;
    }
  }

  void _seedImagesFromCart() {
    for (final item in CartManager().items) {
      final name = item.product.name.trim();
      final url = item.product.imageUrl.trim();
      if (name.isEmpty || url.isEmpty) continue;
      _lineImageCache['name::$name'] = url;
    }
  }

  String? _lookupCachedImage(String orderId, String productName) {
    final name = productName.trim();
    final byOrder = _lineImageCache[_lineCacheKey(orderId, name)];
    if (byOrder != null && byOrder.isNotEmpty) return byOrder;
    return _lineImageCache['name::$name'];
  }

  CartItem _applyCachedImage(String orderId, CartItem line) {
    final cached = _lookupCachedImage(orderId, line.product.name);
    if (cached == null || cached.isEmpty || line.product.imageUrl.isNotEmpty) {
      return line;
    }
    return CartItem(
      product: line.product.copyWith(imageUrl: cached),
      selectedColor: line.selectedColor,
      selectedSize: line.selectedSize,
      quantity: line.quantity,
      variantId: line.variantId,
      apiItemId: line.apiItemId,
      availableStock: line.availableStock,
    );
  }

  List<Order> get orders => List.unmodifiable(_orders);
  int get count => _orders.length;
  bool get isLoading => _loading;
  String? get error => _error;

  /// GET /api/orders
  Future<void> syncFromApi() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _seedImagesFromCart();
      for (final order in _orders) {
        _rememberLineImages(order);
      }
      final list = await _api.fetchOrders();
      _orders.clear();
      for (final order in list) {
        _orders.add(await _enrichOrder(order));
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void addOrder(Order order) {
    _orders.insert(0, order);
    _enrichOrderInBackground(order.id);

    NotificationManager().addNotification(
      NotificationItem(
        id: 'order_new_${order.id}',
        title: 'تم استلام طلبك',
        message: 'طلبك رقم #${order.id} قيد الانتظار حالياً.',
        timestamp: DateTime.now(),
        type: NotificationType.orderPending,
        targetTab: 'orders',
        targetOrderId: order.id,
      ),
    );

    notifyListeners();
  }

  void clearOrders() {
    _orders.clear();
    notifyListeners();
  }

  /// محاكاة «جاهز للاستلام» محلياً — المتجر يُحدّث الحالة عبر POST /api/orders/{id}/prepare.
  void simulateReadyForPickup(String orderId) {
    updateOrderStatus(orderId, 'status_ready');
  }

  /// POST /api/orders/{id}/confirm-delivery ثم إثراء الطلب؛ عند 403 (زبون) يُحدَّث محلياً للمحاكاة.
  Future<void> confirmDelivery(Order order) async {
    final apiId = order.apiId;
    if (apiId != null && apiId > 0) {
      try {
        final updated = await _api.confirmDelivery(apiId);
        await _replaceOrder(await _enrichOrder(updated));
        return;
      } on ApiException catch (e) {
        if (e.statusCode != 403 && e.statusCode != 401) {
          _error = e.message;
          notifyListeners();
          rethrow;
        }
      }
    }
    updateOrderStatus(order.id, 'status_delivered');
  }

  Future<void> refreshOrder(int apiId) async {
    final details = await _api.fetchOrderDetails(apiId);
    if (details == null) return;
    await _replaceOrder(await _enrichOrder(details));
  }

  Future<void> _replaceOrder(Order order) async {
    final i = _orders.indexWhere(
      (o) => o.id == order.id || (o.apiId != null && o.apiId == order.apiId),
    );
    if (i >= 0) {
      _orders[i] = order;
    } else {
      _orders.insert(0, order);
    }
    notifyListeners();
  }

  void updateOrderStatus(String orderId, String newStatus) {
    final i = _orders.indexWhere((o) => o.id == orderId);
    if (i >= 0) {
      _orders[i] = _orders[i].copyWith(status: newStatus);

      if (newStatus == 'status_ready') {
        NotificationManager().addNotification(
          NotificationItem(
            id: 'order_ready_$orderId',
            title: 'طلبك جاهز!',
            message: 'طلبك رقم #$orderId جاهز للاستلام الآن.',
            timestamp: DateTime.now(),
            type: NotificationType.orderReady,
            targetTab: 'orders',
            targetOrderId: orderId,
          ),
        );
      }

      if (newStatus == 'status_delivered') {
        NotificationManager().addNotification(
          NotificationItem(
            id: 'order_delivered_$orderId',
            title: 'تم استلام طلبك',
            message: 'طلبك رقم #$orderId تم استلامه. يمكنك تقييم المتجر والمنتجات الآن.',
            timestamp: DateTime.now(),
            type: NotificationType.orderCompleted,
            targetTab: 'orders',
            targetOrderId: orderId,
          ),
        );
      }

      notifyListeners();
    }
  }

  Future<void> _enrichOrderInBackground(String orderId) async {
    final i = _orders.indexWhere((o) => o.id == orderId);
    if (i < 0) return;
    final enriched = await _enrichOrder(_orders[i]);
    final j = _orders.indexWhere((o) => o.id == orderId);
    if (j < 0) return;
    _orders[j] = enriched;
    notifyListeners();
  }

  Future<Order> _enrichOrder(Order order) async {
    final enrichedItems = <CartItem>[];
    var storeId = order.storeId;
    if (storeId == null && order.storeName.trim().isNotEmpty) {
      storeId = await _enricher.resolveStoreId(order.storeName);
    }

    for (final line in order.items) {
      var enriched = _applyCachedImage(order.id, line);
      enriched = await _enricher.enrichLine(
        enriched,
        storeId: storeId,
        storeName: order.storeName,
      );
      enrichedItems.add(enriched);
    }

    final result = order.copyWith(items: enrichedItems, storeId: storeId);
    _rememberLineImages(result);
    return result;
  }
}
