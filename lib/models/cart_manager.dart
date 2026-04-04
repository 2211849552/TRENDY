import 'package:flutter/material.dart';
import 'cart_item.dart';
import 'product.dart';

class CartManager extends ChangeNotifier {
  // Singleton Pattern
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  void addToCart(Product product, {String color = 'أسود', String size = 'M', int quantity = 1}) {
    // Check if item with same options already exists
    final index = _items.indexWhere((item) => 
      item.product.name == product.name && 
      item.selectedColor == color && 
      item.selectedSize == size
    );

    if (index >= 0) {
      // Allow quantity increment again
      _items[index].quantity += quantity;
    } else {
      // Check if trying to add from a different store
      if (_items.isNotEmpty && _items.first.product.storeName != product.storeName) {
        throw Exception('لا يمكنك إضافة منتجات من متجرين مختلفين في نفس الوقت. يرجى إتمام الطلب الحالي أو تفريغ السلة.');
      }

      _items.add(CartItem(
        product: product,
        selectedColor: color,
        selectedSize: size,
        quantity: quantity,
      ));
    }
    notifyListeners();
  }

  void updateQuantity(CartItem item, int delta) {
    if (item.quantity + delta > 0) {
      item.quantity += delta;
      notifyListeners();
    } else {
      removeFromCart(item);
    }
  }

  void removeFromCart(CartItem item) {
    _items.remove(item);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
