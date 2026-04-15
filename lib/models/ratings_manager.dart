import 'package:flutter/foundation.dart';

class RatingsManager extends ChangeNotifier {
  static final RatingsManager _instance = RatingsManager._internal();
  factory RatingsManager() => _instance;
  RatingsManager._internal();

  final Map<String, List<double>> _storeRatings = {};
  final Map<String, List<double>> _productRatings = {};
  final Map<String, double> _storeRatingByOrder = {};
  final Map<String, Map<String, double>> _productRatingsByOrder = {};

  bool hasRatedStoreForOrder(String orderId) {
    return _storeRatingByOrder.containsKey(orderId);
  }

  bool hasRatedProductForOrder(String orderId, String productKey) {
    return _productRatingsByOrder[orderId]?.containsKey(productKey) ?? false;
  }

  bool hasRatedAllProductsForOrder(String orderId, List<String> productKeys) {
    final rated = _productRatingsByOrder[orderId];
    if (rated == null) return false;
    for (final key in productKeys) {
      if (!rated.containsKey(key)) return false;
    }
    return true;
  }

  void submitStoreRating({
    required String orderId,
    required String storeKey,
    required double rating,
  }) {
    final safeRating = rating.clamp(1.0, 5.0);
    if (_storeRatingByOrder.containsKey(orderId)) return;
    _storeRatingByOrder[orderId] = safeRating;
    _storeRatings.putIfAbsent(storeKey, () => []).add(safeRating);
    notifyListeners();
  }

  void submitProductRating({
    required String orderId,
    required String productKey,
    required double rating,
  }) {
    final safeRating = rating.clamp(1.0, 5.0);
    final byOrder = _productRatingsByOrder.putIfAbsent(orderId, () => {});
    if (byOrder.containsKey(productKey)) return;
    byOrder[productKey] = safeRating;
    _productRatings.putIfAbsent(productKey, () => []).add(safeRating);
    notifyListeners();
  }

  double storeRatingOrBase(String storeKey, double baseRating) {
    final rates = _storeRatings[storeKey];
    if (rates == null || rates.isEmpty) return baseRating;
    final avg = rates.reduce((a, b) => a + b) / rates.length;
    return ((avg + baseRating) / 2).clamp(1.0, 5.0);
  }

  double productRatingOrBase(String productKey, double baseRating) {
    final rates = _productRatings[productKey];
    if (rates == null || rates.isEmpty) return baseRating;
    final avg = rates.reduce((a, b) => a + b) / rates.length;
    return ((avg + baseRating) / 2).clamp(1.0, 5.0);
  }
}
