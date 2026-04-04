import 'cart_item.dart';

class Order {
  final String id;
  final DateTime date;
  final List<CartItem> items;
  final double totalPrice;
  /// e.g. قيد الانتظار، جاهز للاستلام، تم التوصيل
  final String status;

  Order({
    required this.id,
    required this.date,
    required this.items,
    required this.totalPrice,
    this.status = 'قيد الانتظار',
  });

  Order copyWith({
    String? id,
    DateTime? date,
    List<CartItem>? items,
    double? totalPrice,
    String? status,
  }) {
    return Order(
      id: id ?? this.id,
      date: date ?? this.date,
      items: items ?? this.items,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
    );
  }
}
