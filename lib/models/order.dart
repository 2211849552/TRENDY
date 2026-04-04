import 'cart_item.dart';

class Order {
  final String id;
  final DateTime date;
  final List<CartItem> items;
  final double totalPrice;
  final String status; // 'قيد المعالجة', 'تم الشحن', 'تم التوصيل'

  Order({
    required this.id,
    required this.date,
    required this.items,
    required this.totalPrice,
    this.status = 'قيد المعالجة',
  });
}
