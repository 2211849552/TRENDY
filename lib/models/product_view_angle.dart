/// زوايا عرض المنتج في المعرض (مثل متاجر الأزياء).
enum ProductViewAngle {
  front,
  back,
  upperDetail,
  lowerDetail,
  side,
  fullBody,
}

extension ProductViewAngleX on ProductViewAngle {
  String get labelKey {
    switch (this) {
      case ProductViewAngle.front:
        return 'view_front';
      case ProductViewAngle.back:
        return 'view_back';
      case ProductViewAngle.upperDetail:
        return 'view_upper';
      case ProductViewAngle.lowerDetail:
        return 'view_lower';
      case ProductViewAngle.side:
        return 'view_side';
      case ProductViewAngle.fullBody:
        return 'view_full';
    }
  }
}
