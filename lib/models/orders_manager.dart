import 'package:flutter/material.dart';
import 'order.dart';

class OrdersManager extends ChangeNotifier {
  static final OrdersManager _instance = OrdersManager._internal();
  factory OrdersManager() => _instance;
  OrdersManager._internal();

  final List<Order> _orders = [];

  List<Order> get orders => List.unmodifiable(_orders);

  int get count => _orders.length;

  void addOrder(Order order) {
    _orders.insert(0, order); // Add new orders at the top
    notifyListeners();
  }

  void clearOrders() {
    _orders.clear();
    notifyListeners();
  }
}
