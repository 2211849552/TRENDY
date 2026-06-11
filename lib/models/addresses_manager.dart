import 'package:flutter/foundation.dart';

import '../services/api/addresses_api.dart';
import '../services/api/api_exception.dart';
import 'auth_session.dart';
import 'saved_address.dart';

export 'saved_address.dart';

class AddressesManager extends ChangeNotifier {
  static final AddressesManager _instance = AddressesManager._();
  factory AddressesManager() => _instance;
  AddressesManager._();

  static const defaultLat = 32.8872;
  static const defaultLng = 13.1913;

  final AddressesApi _api = AddressesApi();
  final List<SavedAddress> _addresses = [];
  String _selectedId = '';
  bool _loading = false;
  String? _error;

  bool get isLoading => _loading;
  String? get error => _error;
  List<SavedAddress> get addresses => List.unmodifiable(_addresses);
  String get selectedId => _selectedId;

  SavedAddress? get selected {
    for (final a in _addresses) {
      if (a.id == _selectedId) return a;
    }
    return _addresses.isEmpty ? null : _addresses.first;
  }

  /// GET /api/addresses
  Future<void> syncFromApi() async {
    if (!AuthSession.instance.isAuthenticated) {
      _addresses.clear();
      _selectedId = '';
      _error = null;
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final list = await _api.fetchAddresses();
      _addresses
        ..clear()
        ..addAll(list);
      if (_selectedId.isEmpty || !_addresses.any((a) => a.id == _selectedId)) {
        _selectedId = _addresses.isEmpty ? '' : _addresses.first.id;
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void select(String id) {
    if (_selectedId == id) return;
    if (!_addresses.any((a) => a.id == id)) return;
    _selectedId = id;
    notifyListeners();
  }

  /// POST /api/addresses للعناوين الجديدة فقط (api.md لا يوفّر تعديل/حذف).
  Future<bool> upsert(SavedAddress address, {bool selectAfter = false}) async {
    _error = null;

    if (AuthSession.instance.isAuthenticated) {
      if (address.apiId != null) {
        _error = 'addr_edit_not_supported';
        notifyListeners();
        return false;
      }

      try {
        final fallbackPhone = AuthSession.instance.user?.phone;
        final payload = await _api.createAddress(
          _withFallbackPhone(address, fallbackPhone),
        );
        _addresses.add(payload);
        if (selectAfter) _selectedId = payload.id;
        notifyListeners();
        return true;
      } on ApiException catch (e) {
        _error = e.message;
        notifyListeners();
        return false;
      } catch (e) {
        _error = e.toString();
        notifyListeners();
        return false;
      }
    }

    final index = _addresses.indexWhere((a) => a.id == address.id);
    if (index >= 0) {
      _addresses[index] = address;
    } else {
      _addresses.add(address);
    }
    if (selectAfter) _selectedId = address.id;
    notifyListeners();
    return true;
  }

  Future<bool> remove(String id) async {
    _error = null;
    final index = _addresses.indexWhere((a) => a.id == id);
    if (index < 0) return false;

    final address = _addresses[index];
    if (AuthSession.instance.isAuthenticated && address.apiId != null) {
      _error = 'addr_delete_not_supported';
      notifyListeners();
      return false;
    }

    _addresses.removeAt(index);
    if (_addresses.isEmpty) {
      _selectedId = '';
    } else if (_selectedId == id) {
      _selectedId = _addresses.first.id;
    }
    notifyListeners();
    return true;
  }

  String nextId() => 'addr_${DateTime.now().millisecondsSinceEpoch}';

  SavedAddress _withFallbackPhone(SavedAddress address, String? phone) {
    if (address.phone != null && address.phone!.trim().isNotEmpty) {
      return address;
    }
    if (phone == null || phone.trim().isEmpty) return address;
    return address.copyWith(phone: phone.trim());
  }
}
