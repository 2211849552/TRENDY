import 'cart_item.dart';

class Order {
  final String id;
  final DateTime date;
  final List<CartItem> items;
  final double totalPrice;
  /// e.g. قيد الانتظار، جاهز للاستلام، تم التوصيل
  final String status;
  final String storeName;
  final String paymentMethod;

  Order({
    required this.id,
    required this.date,
    required this.items,
    required this.totalPrice,
    this.status = 'قيد الانتظار',
    required this.storeName,
    required this.paymentMethod,
  });

  Order copyWith({
    String? id,
    DateTime? date,
    List<CartItem>? items,
    double? totalPrice,
    String? status,
    String? storeName,
    String? paymentMethod,
  }) {
    return Order(
      id: id ?? this.id,
      date: date ?? this.date,
      items: items ?? this.items,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      storeName: storeName ?? this.storeName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}
