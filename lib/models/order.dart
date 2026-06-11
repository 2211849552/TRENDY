import 'cart_item.dart';

class Order {
  final String id;
  final int? apiId;
  final DateTime date;
  final List<CartItem> items;
  final double totalPrice;
  /// e.g. قيد الانتظار، جاهز للاستلام، تم التوصيل
  final String status;
  final String storeName;
  final int? storeId;
  final String paymentMethod;

  Order({
    required this.id,
    this.apiId,
    required this.date,
    required this.items,
    required this.totalPrice,
    this.status = 'قيد الانتظار',
    required this.storeName,
    this.storeId,
    required this.paymentMethod,
  });

  Order copyWith({
    String? id,
    int? apiId,
    DateTime? date,
    List<CartItem>? items,
    double? totalPrice,
    String? status,
    String? storeName,
    int? storeId,
    String? paymentMethod,
  }) {
    return Order(
      id: id ?? this.id,
      apiId: apiId ?? this.apiId,
      date: date ?? this.date,
      items: items ?? this.items,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      storeName: storeName ?? this.storeName,
      storeId: storeId ?? this.storeId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}
