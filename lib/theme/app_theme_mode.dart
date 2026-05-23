import 'package:flutter/material.dart';

/// وضع مظهر التطبيق: داكن أو فاتح (أبيض).
class AppThemeMode extends ChangeNotifier {
  AppThemeMode._();
  static final AppThemeMode instance = AppThemeMode._();

  bool _isLight = false;

  bool get isLight => _isLight;

  void setLightMode(bool value) {
    if (_isLight == value) return;
    _isLight = value;
    notifyListeners();
  }

  void toggle() => setLightMode(!_isLight);
}
