import 'package:flutter/foundation.dart';
import '../data/product_reviews_seed.dart';
import 'customer_review.dart';
import 'product_rating_detail.dart';

class RatingsManager extends ChangeNotifier {
  static final RatingsManager _instance = RatingsManager._internal();
  factory RatingsManager() => _instance;
  RatingsManager._internal();

  final Map<String, List<double>> _storeRatings = {};
  final Map<String, List<double>> _productRatings = {};
  final Map<String, double> _storeRatingByOrder = {};
  final Map<String, Map<String, double>> _productRatingsByOrder = {};
  final Map<String, Map<String, ProductRatingDetail>> _productDetailsByOrder = {};
  final Map<String, List<CustomerReview>> _userReviewsByProduct = {};

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

  ProductRatingDetail? productRatingDetail(String orderId, String productKey) {
    return _productDetailsByOrder[orderId]?[productKey];
  }

  bool isOrderFullyRated(String orderId, List<String> productKeys) {
    if (!hasRatedStoreForOrder(orderId)) return false;
    return hasRatedAllProductsForOrder(orderId, productKeys);
  }

  List<CustomerReview> reviewsForProduct(String productKey) {
    final seed = ProductReviewsSeed.reviewsFor(productKey);
    final user = _userReviewsByProduct[productKey] ?? [];
    return [...user, ...seed];
  }

  double? storeRatingForOrder(String orderId) => _storeRatingByOrder[orderId];

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
    String? comment,
    List<String> imagePaths = const [],
  }) {
    final safeRating = rating.clamp(1.0, 5.0);
    final byOrder = _productRatingsByOrder.putIfAbsent(orderId, () => {});
    if (byOrder.containsKey(productKey)) return;
    byOrder[productKey] = safeRating;
    _productRatings.putIfAbsent(productKey, () => []).add(safeRating);

    final details = _productDetailsByOrder.putIfAbsent(orderId, () => {});
    final trimmed = comment?.trim();
    final savedComment = trimmed == null || trimmed.isEmpty ? null : trimmed;
    details[productKey] = ProductRatingDetail(
      rating: safeRating,
      comment: savedComment,
      imagePaths: List<String>.from(imagePaths),
    );

    _userReviewsByProduct.putIfAbsent(productKey, () => []).insert(
      0,
      CustomerReview(
        authorName: 'أنت',
        rating: safeRating,
        comment: savedComment ?? '',
        imageAssetPath: imagePaths.isNotEmpty ? imagePaths.first : null,
        date: DateTime.now(),
      ),
    );
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
