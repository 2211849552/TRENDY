import 'product.dart';

class CartItem {
  final Product product;
  String selectedColor;
  String selectedSize;
  int quantity;
  final int? apiItemId;
  final int? variantId;
  final int? availableStock;

  CartItem({
    required this.product,
    required this.selectedColor,
    required this.selectedSize,
    this.quantity = 1,
    this.apiItemId,
    this.variantId,
    this.availableStock,
  });

  double get totalPrice => product.price * quantity;
}
