import 'product.dart';

class CartItem {
  final Product product;
  final String selectedColor;
  final String selectedSize;
  int quantity;

  CartItem({
    required this.product,
    required this.selectedColor,
    required this.selectedSize,
    this.quantity = 1,
  });

  double get totalPrice => product.price * quantity;
}
