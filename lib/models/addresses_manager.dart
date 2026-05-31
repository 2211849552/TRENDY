import 'package:flutter/foundation.dart';

class SavedAddress {
  final String id;
  final String label;
  final String streetLine;
  final String city;
  final String? description;
  final double lat;
  final double lng;

  const SavedAddress({
    required this.id,
    required this.label,
    required this.streetLine,
    required this.city,
    this.description,
    required this.lat,
    required this.lng,
  });

  SavedAddress copyWith({
    String? label,
    String? streetLine,
    String? city,
    String? description,
    double? lat,
    double? lng,
  }) {
    return SavedAddress(
      id: id,
      label: label ?? this.label,
      streetLine: streetLine ?? this.streetLine,
      city: city ?? this.city,
      description: description ?? this.description,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }
}

class AddressesManager extends ChangeNotifier {
  static final AddressesManager _instance = AddressesManager._();
  factory AddressesManager() => _instance;
  AddressesManager._();

  static const defaultLat = 32.8872;
  static const defaultLng = 13.1913;

  final List<SavedAddress> _addresses = [
    const SavedAddress(
      id: 'addr_1',
      label: 'جرابه',
      streetLine: 'شارع عوف بن عفراء',
      city: 'طرابلس',
      lat: defaultLat,
      lng: defaultLng,
    ),
    const SavedAddress(
      id: 'addr_2',
      label: 'المنصوره',
      streetLine: 'شارع الجمهورية',
      city: 'طرابلس',
      lat: 32.8920,
      lng: 13.1800,
    ),
    const SavedAddress(
      id: 'addr_3',
      label: 'مطعم التقسيم جرابه',
      streetLine: 'جرابه',
      city: 'طرابلس',
      lat: 32.9000,
      lng: 13.1650,
    ),
  ];

  String _selectedId = 'addr_1';

  List<SavedAddress> get addresses => List.unmodifiable(_addresses);
  String get selectedId => _selectedId;

  SavedAddress? get selected {
    for (final a in _addresses) {
      if (a.id == _selectedId) return a;
    }
    return _addresses.isEmpty ? null : _addresses.first;
  }

  void select(String id) {
    if (_selectedId == id) return;
    if (!_addresses.any((a) => a.id == id)) return;
    _selectedId = id;
    notifyListeners();
  }

  void upsert(SavedAddress address, {bool selectAfter = false}) {
    final index = _addresses.indexWhere((a) => a.id == address.id);
    if (index >= 0) {
      _addresses[index] = address;
    } else {
      _addresses.add(address);
    }
    if (selectAfter) _selectedId = address.id;
    notifyListeners();
  }

  void remove(String id) {
    _addresses.removeWhere((a) => a.id == id);
    if (_addresses.isEmpty) {
      _selectedId = '';
    } else if (_selectedId == id) {
      _selectedId = _addresses.first.id;
    }
    notifyListeners();
  }

  String nextId() => 'addr_${DateTime.now().millisecondsSinceEpoch}';
}
