import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// تخزين توكن FCM محلياً حتى يُربط firebase_messaging لاحقاً.
class PushTokenStore {
  PushTokenStore._();

  static final PushTokenStore instance = PushTokenStore._();

  static const _tokenKey = 'fcm_device_token';

  String? _token;
  bool _loaded = false;

  String? get token => _token;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _loaded = true;
  }

  Future<void> saveToken(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) return;
    _token = trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, trimmed);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}

String pushPlatformLabel() {
  if (kIsWeb) return 'web';
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      return 'ios';
    case TargetPlatform.android:
      return 'android';
    default:
      return 'web';
  }
}
