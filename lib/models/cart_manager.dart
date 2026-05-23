import 'package:flutter/material.dart';
import 'cart_item.dart';
import 'product.dart';

/// يُرمى عند محاولة إضافة منتج من متجر مختلف عن منتجات السلة الحالية.
class CartSingleStoreException implements Exception {
  const CartSingleStoreException();
}

class CartManager extends ChangeNotifier {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  /// مفتاح المتجر الحالي في السلة، أو null إذا كانت فارغة.
  String? get currentStoreKey =>
      _items.isEmpty ? null : _items.first.product.storeName;

  void addToCart(Product product, {String color = 'أسود', String size = 'M', int quantity = 1}) {
    final index = _items.indexWhere(
      (item) =>
          item.product.name == product.name &&
          item.selectedColor == color &&
          item.selectedSize == size,
    );

    if (index >= 0) {
      _items[index].quantity += quantity;
    } else {
      if (_items.isNotEmpty && _items.first.product.storeName != product.storeName) {
        throw const CartSingleStoreException();
      }
      _items.add(
        CartItem(
          product: product,
          selectedColor: color,
          selectedSize: size,
          quantity: quantity,
        ),
      );
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

  void updateAttributes(CartItem item, {String? color, String? size}) {
    if (color != null && color.isNotEmpty) item.selectedColor = color;
    if (size != null && size.isNotEmpty) item.selectedSize = size;
    notifyListeners();
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
