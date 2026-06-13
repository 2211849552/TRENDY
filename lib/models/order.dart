import 'cart_item.dart';

class Order {
  final String id;
  final int? apiId;
  final DateTime date;
  final List<CartItem> items;
  final double totalPrice;
  final double deliveryFee;
  /// e.g. status_pending, status_ready, status_delivered
  final String status;
  final String storeName;
  final int? storeId;
  final String paymentMethod;
  final String? otpCode;
  final String? driverName;
  final DateTime? deliveredAt;

  Order({
    required this.id,
    this.apiId,
    required this.date,
    required this.items,
    required this.totalPrice,
    this.deliveryFee = 0,
    this.status = 'status_pending',
    required this.storeName,
    this.storeId,
    required this.paymentMethod,
    this.otpCode,
    this.driverName,
    this.deliveredAt,
  });

  Order copyWith({
    String? id,
    int? apiId,
    DateTime? date,
    List<CartItem>? items,
    double? totalPrice,
    double? deliveryFee,
    String? status,
    String? storeName,
    int? storeId,
    String? paymentMethod,
    String? otpCode,
    String? driverName,
    DateTime? deliveredAt,
  }) {
    return Order(
      id: id ?? this.id,
      apiId: apiId ?? this.apiId,
      date: date ?? this.date,
      items: items ?? this.items,
      totalPrice: totalPrice ?? this.totalPrice,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      status: status ?? this.status,
      storeName: storeName ?? this.storeName,
      storeId: storeId ?? this.storeId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      otpCode: otpCode ?? this.otpCode,
      driverName: driverName ?? this.driverName,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }
}
