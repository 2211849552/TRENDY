import '../services/store_location.dart';

/// بيانات المتاجر المتاحة في التطبيق (مفاتيح ثابتة — التسميات عبر [tr]).
class StoreCatalog {
  StoreCatalog._();

  static const List<Map<String, dynamic>> stores = [
    {
      'name': 'store_elegance',
      'category': 'cat_dresses',
      'rating': 4.8,
      'isElectronic': false,
      'location': StoreLocation(32.8872, 13.1913),
      'displayDistanceKm': 2.5,
      'deliveryFee': 8.0,
      'imageUrl': 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&q=80&w=800',
      'discount': '40%',
    },
    {
      'name': 'store_fashion',
      'category': 'cat_mens_wear',
      'rating': 4.5,
      'isElectronic': false,
      'location': StoreLocation(32.8920, 13.1800),
      'displayDistanceKm': 1.2,
      'deliveryFee': 5.0,
      'imageUrl': 'https://images.unsplash.com/photo-1490114538077-0a7f8cb49891?auto=format&fit=crop&q=80&w=800',
      'discount': null,
    },
    {
      'name': 'store_gentle',
      'category': 'cat_mens_wear',
      'rating': 4.6,
      'isElectronic': false,
      'location': StoreLocation(32.8895, 13.2050),
      'displayDistanceKm': 0.8,
      'deliveryFee': 4.0,
      'imageUrl': 'https://images.unsplash.com/photo-1593032465175-481ac7f401a0?auto=format&fit=crop&q=80&w=800',
      'discount': '30%',
    },
    {
      'name': 'store_luxury',
      'category': 'cat_evening_dresses',
      'rating': 4.7,
      'isElectronic': true,
      'location': StoreLocation(32.8760, 13.1860),
      'displayDistanceKm': 5.0,
      'deliveryFee': 12.0,
      'imageUrl': 'https://images.unsplash.com/photo-1566174053879-31528523f8ae?auto=format&fit=crop&q=80&w=800',
      'discount': '25%',
    },
    {
      'name': 'store_kids',
      'category': 'cat_kids_clothing',
      'rating': 4.9,
      'isElectronic': false,
      'location': StoreLocation(32.9000, 13.1650),
      'displayDistanceKm': 3.4,
      'deliveryFee': 7.0,
      'imageUrl': 'assets/images/stores/store_kids.jpg',
      'discount': '25%',
    },
    {
      'name': 'store_top',
      'category': 'cat_mens_wear',
      'rating': 4.9,
      'isElectronic': true,
      'location': StoreLocation(32.8850, 13.1700),
      'displayDistanceKm': 4.2,
      'deliveryFee': 10.0,
      'imageUrl': 'assets/images/stores/store_top.jpg',
      'discount': null,
    },
  ];

  static Map<String, dynamic>? findByKey(String storeKey) {
    for (final store in stores) {
      if (store['name'] == storeKey) return store;
    }
    return null;
  }
}
