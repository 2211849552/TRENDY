import 'package:flutter/material.dart';

/// لوحة ألوان Trendy — خلفية بنفسجية داكنة مع تدرج بنفسجي → أزرق.
class AppColors {
  AppColors._();

  static const background = Color(0xFF121026);
  static const surface = Color(0xFF1E1B4B);
  static const surfaceElevated = Color(0xFF1C1A33);
  static const card = Color(0xFF252347);

  static const primary = Color(0xFFA855F7);
  static const secondary = Color(0xFF3B82F6);
  static const accent = Color(0xFFC084FC);

  static const textPrimary = Colors.white;
  static const textMuted = Color(0xFF94A3B8);
  static const textOnGradient = Colors.white;

  static const outline = Color(0x1AFFFFFF);
  static const error = Color(0xFFFF4D6D);

  /// خلفية شاشات ما قبل تسجيل الدخول — مطابقة لورق الشعار.
  static const authBackground = Color(0xFFEFEFF0);
  /// خلفية شاشة الإقلاع — مطابقة لخلفية ملف الشعار (#F7F5F6).
  static const splashBranding = Color(0xFFF7F5F6);
  static const authTextMuted = Color(0xFF64748B);
  /// لون حرف T في الشعار — لمربعات تسجيل الدخول.
  static const authNavy = Color(0xFF33416E);

  static const brandGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primary, secondary],
  );

  static const brandGradientRtl = LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [primary, secondary],
  );

  static LinearGradient verticalBrand({double topAlpha = 0.95, double bottomAlpha = 0.85}) {
    return LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        primary.withValues(alpha: topAlpha),
        secondary.withValues(alpha: bottomAlpha),
      ],
    );
  }

  static Color cardTint([double alpha = 0.12]) => primary.withValues(alpha: alpha);
}
