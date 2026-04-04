import 'package:flutter/material.dart';

/// يحفظ لغة الواجهة ويُشعِر المستمعين لإعادة بناء [MaterialApp].
class AppLocale extends ChangeNotifier {
  AppLocale._();
  static final AppLocale instance = AppLocale._();

  Locale _locale = const Locale('ar');

  Locale get locale => _locale;

  bool get isRtl => _locale.languageCode == 'ar';

  void setLocale(Locale locale) {
    final code = locale.languageCode;
    if (code != 'ar' && code != 'en') return;
    final next = Locale(code);
    if (_locale == next) return;
    _locale = next;
    notifyListeners();
  }
}
