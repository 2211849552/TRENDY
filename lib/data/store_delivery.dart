/// حساب وعرض رسوم توصيل المتاجر.
class StoreDelivery {
  StoreDelivery._();

  static double feeFor(Map<String, dynamic> store, {double? distanceKm}) {
    final fixed = store['deliveryFee'] as num?;
    if (fixed != null) return fixed.toDouble();

    final km = distanceKm ??
        (store['displayDistanceKm'] as num?)?.toDouble() ??
        2.0;
    return (3 + km * 1.5).clamp(3.0, 25.0);
  }
}
