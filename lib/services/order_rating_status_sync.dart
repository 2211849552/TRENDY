import '../models/auth_session.dart';
import '../models/order.dart';
import '../models/ratings_manager.dart';
import '../utils/rating_ownership.dart';
import 'api/api_exception.dart';
import 'api/profile_api.dart';
import 'api/ratings_api.dart';
import 'product_line_enricher.dart';

/// يطابق حالة «تم التقييم» مع السيرver بعد تحميل الطلبات.
class OrderRatingStatusSync {
  OrderRatingStatusSync({
    RatingsApi? ratingsApi,
    ProductLineEnricher? enricher,
    ProfileApi? profileApi,
  })  : _ratingsApi = ratingsApi ?? RatingsApi(),
        _enricher = enricher ?? ProductLineEnricher(),
        _profileApi = profileApi ?? ProfileApi();

  final RatingsApi _ratingsApi;
  final ProductLineEnricher _enricher;
  final ProfileApi _profileApi;

  Future<void> syncOrders(List<Order> orders, RatingsManager ratings) async {
    await ratings.ensureLoaded();
    if (!AuthSession.instance.isAuthenticated) return;
    await _ensureCustomerProfileId();

    for (final order in orders) {
      if (order.status != 'status_delivered') continue;

      final productKeys = order.items.map((e) => e.product.name).toList();
      if (ratings.hasRatedOrder(order.id, productKeys, apiId: order.apiId)) {
        continue;
      }

      final ratedOnServer = await _syncOrderRatingsFromServer(order, ratings);
      if (ratedOnServer) {
        await ratings.markOrderRated(order.id, apiId: order.apiId);
      }
    }
  }

  Future<void> _ensureCustomerProfileId() async {
    final user = AuthSession.instance.user;
    if (user == null || user.customerProfileId != null) return;
    try {
      final profile = await _profileApi.fetchProfile();
      if (profile.id != null) {
        await AuthSession.instance.updateUser(
          user.copyWith(customerProfileId: profile.id),
        );
      }
    } on ApiException {
      // نعتمد على الاسم أو التخزين المحلي.
    }
  }

  Future<bool> _syncOrderRatingsFromServer(Order order, RatingsManager ratings) async {
    var storeId = order.storeId;
    storeId ??= await _enricher.resolveStoreId(order.storeName);

    if (storeId != null && !ratings.hasRatedStoreForOrder(order.id)) {
      try {
        final page = await _ratingsApi.fetchStoreRatings(storeId, perPage: 50);
        for (final rating in page.ratings) {
          if (!ratingBelongsToCurrentUser(
            authorName: rating.authorName,
            authorId: rating.authorId,
          )) {
            continue;
          }
          ratings.submitStoreRating(
            orderId: order.id,
            storeKey: order.storeName,
            rating: rating.stars.toDouble(),
          );
          break;
        }
      } on ApiException {
        // تجاهل — نعتمد على التخزين المحلي
      }
    }

    if (order.items.isEmpty) return false;

    for (final line in order.items) {
      final key = line.product.name;
      if (ratings.hasRatedProductForOrder(order.id, key)) continue;

      var productId = line.product.id;
      productId ??= await _enricher.resolveProductId(
        key,
        storeId: order.storeId ?? storeId,
        storeName: order.storeName,
      );
      if (productId == null) continue;

      try {
        final page = await _ratingsApi.fetchProductRatings(productId, perPage: 30);
        for (final rating in page.ratings) {
          if (!ratingBelongsToCurrentUser(
            authorName: rating.authorName,
            authorId: rating.authorId,
          )) {
            continue;
          }
          ratings.submitProductRating(
            orderId: order.id,
            productKey: key,
            rating: rating.stars.toDouble(),
            comment: rating.comment.isNotEmpty ? rating.comment : null,
          );
          break;
        }
      } on ApiException {
        // تجاهل — نعتمد على التخزين المحلي
      }
    }

    for (final line in order.items) {
      if (!ratings.hasRatedProductForOrder(order.id, line.product.name)) {
        return false;
      }
    }
    return true;
  }
}
