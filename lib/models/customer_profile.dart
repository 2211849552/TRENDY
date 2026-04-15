import 'package:flutter/foundation.dart';

class CustomerProfile {
  final String name;
  final String email;
  final String phone;

  const CustomerProfile({
    required this.name,
    required this.email,
    required this.phone,
  });

  CustomerProfile copyWith({
    String? name,
    String? email,
    String? phone,
  }) {
    return CustomerProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }
}

class CustomerProfileStore extends ChangeNotifier {
  static final CustomerProfileStore _instance = CustomerProfileStore._();
  factory CustomerProfileStore() => _instance;
  CustomerProfileStore._();

  CustomerProfile? _current;
  CustomerProfile? get current => _current;

  bool get isLoggedIn {
    final c = _current;
    return c != null && (c.email.trim().isNotEmpty || c.name.trim().isNotEmpty);
  }

  void setProfile({
    required String name,
    required String email,
    required String phone,
  }) {
    _current = CustomerProfile(
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
    );
    notifyListeners();
  }

  void clear() {
    _current = null;
    notifyListeners();
  }
}

