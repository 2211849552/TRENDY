import 'package:flutter/material.dart';
import '../models/product_view_angle.dart';

/// إطار العرض لكل زاوية (قص/تكبير/انعكاس) على نفس المنتج.
class ProductViewFrame extends StatelessWidget {
  final ProductViewAngle angle;
  final Widget child;

  const ProductViewFrame({
    super.key,
    required this.angle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    switch (angle) {
      case ProductViewAngle.front:
        return child;
      case ProductViewAngle.back:
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(-1.0, 1.0),
          child: child,
        );
      case ProductViewAngle.upperDetail:
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: 0.58,
            child: Transform.scale(
              scale: 1.35,
              alignment: Alignment.topCenter,
              child: child,
            ),
          ),
        );
      case ProductViewAngle.lowerDetail:
        return ClipRect(
          child: Align(
            alignment: Alignment.bottomCenter,
            heightFactor: 0.55,
            child: Transform.scale(
              scale: 1.3,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          ),
        );
      case ProductViewAngle.side:
        return ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: 0.72,
            child: Transform.scale(
              scale: 1.2,
              alignment: Alignment.centerLeft,
              child: child,
            ),
          ),
        );
      case ProductViewAngle.fullBody:
        return ClipRect(
          child: Align(
            alignment: Alignment.center,
            heightFactor: 0.92,
            child: child,
          ),
        );
    }
  }
}
