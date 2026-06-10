import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'customer_profile.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  final int? id;
  final String name;
  final String email;
  final String phone;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final name = _firstNonEmpty([
      json['name']?.toString(),
      json['full_name']?.toString(),
      json['display_name']?.toString(),
      json['username']?.toString(),
    ]);
    final phone = _firstNonEmpty([
      json['phone']?.toString(),
      json['mobile']?.toString(),
      json['phone_number']?.toString(),
    ]);

    return AuthUser(
      id: _asInt(json['id']),
      name: name ?? '',
      email: '${json['email'] ?? ''}'.trim(),
      phone: phone ?? '',
    );
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
      };

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

/// جلسة المصادقة — توكن Sanctum + بيانات الزبون أو وضع الزائر.
class AuthSession extends ChangeNotifier {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';
  static const _guestKey = 'auth_guest';

  String? _token;
  AuthUser? _user;
  bool _isGuest = false;
  bool _loaded = false;

  String? get token => _token;
  AuthUser? get user => _user;
  bool get isGuest => _isGuest;
  bool get isAuthenticated => !_isGuest && _token != null && _token!.isNotEmpty;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _isGuest = prefs.getBool(_guestKey) ?? false;

    final rawUser = prefs.getString(_userKey);
    if (rawUser != null && rawUser.isNotEmpty) {
      try {
        final map = jsonDecode(rawUser);
        if (map is Map<String, dynamic>) {
          _user = AuthUser.fromJson(map);
        }
      } catch (_) {
        _user = null;
      }
    }

    _syncProfileStore();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setAuthenticated({
    required String token,
    required AuthUser user,
  }) async {
    _token = token;
    _user = user;
    _isGuest = false;
    await _persist();
    _syncProfileStore();
    notifyListeners();
  }

  Future<void> updateUser(AuthUser user) async {
    _user = user;
    await _persist();
    _syncProfileStore();
    notifyListeners();
  }

  Future<void> setGuest() async {
    _token = null;
    _user = null;
    _isGuest = true;
    await _persist();
    CustomerProfileStore().clear();
    notifyListeners();
  }

  Future<void> clear() async {
    _token = null;
    _user = null;
    _isGuest = false;
    await _persist();
    CustomerProfileStore().clear();
    notifyListeners();
  }

  void _syncProfileStore() {
    final current = _user;
    if (current == null || _isGuest) return;
    CustomerProfileStore().setProfile(
      name: current.name,
      email: current.email,
      phone: current.phone,
    );
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token == null || _token!.isEmpty) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, _token!);
    }

    if (_user == null) {
      await prefs.remove(_userKey);
    } else {
      await prefs.setString(_userKey, jsonEncode(_user!.toJson()));
    }

    await prefs.setBool(_guestKey, _isGuest);
  }
}
