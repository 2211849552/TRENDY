import 'package:flutter/material.dart';
import 'order.dart';
import 'notification_manager.dart';
import 'notification_item.dart';

class OrdersManager extends ChangeNotifier {
  static final OrdersManager _instance = OrdersManager._internal();
  factory OrdersManager() => _instance;
  OrdersManager._internal();

  final List<Order> _orders = [];

  List<Order> get orders => List.unmodifiable(_orders);

  int get count => _orders.length;

  void addOrder(Order order) {
    _orders.insert(0, order); // Add new orders at the top
    
    // Trigger notification
    NotificationManager().addNotification(
      NotificationItem(
        id: 'order_new_${order.id}',
        title: 'تم استلام طلبك',
        message: 'طلبك رقم #${order.id} قيد الانتظار حالياً.',
        timestamp: DateTime.now(),
        type: NotificationType.orderPending,
      ),
    );
    
    notifyListeners();
  }

  void clearOrders() {
    _orders.clear();
    notifyListeners();
  }

  void updateOrderStatus(String orderId, String newStatus) {
    final i = _orders.indexWhere((o) => o.id == orderId);
    if (i >= 0) {
      _orders[i] = _orders[i].copyWith(status: newStatus);

      // Trigger notification based on status
      if (newStatus == 'جاهز للاستلام') {
        NotificationManager().addNotification(
          NotificationItem(
            id: 'order_ready_${orderId}',
            title: 'طلبك جاهز!',
            message: 'طلبك رقم #$orderId جاهز للاستلام الآن.',
            timestamp: DateTime.now(),
            type: NotificationType.orderReady,
          ),
        );
      }
      
      notifyListeners();
    }
  }

  bool canCheckoutFromStore(String storeName) {
    // Orders that are not delivered yet are considered active
    final activeOrders = _orders.where((o) => o.status != 'تم التوصيل');
    
    // If there is an active order from a DIFFERENT store, prevent checkout
    for (final order in activeOrders) {
      if (order.items.isNotEmpty && order.items.first.product.storeName != storeName) {
        return false;
      }
    }
    return true;
  }
}
