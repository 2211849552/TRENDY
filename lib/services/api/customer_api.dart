import 'api_client.dart';
import 'order_ratings_service.dart';
import 'orders_api.dart';
import 'ratings_api.dart';

export 'customer_api_paths.dart';
export 'order_ratings_service.dart';
export 'orders_api.dart';
export 'ratings_api.dart';

/// نقطة دخول API تطبيق الزبون — انظر `lib/api.md`:
///
/// **الطلبات [16]**
/// - [OrdersApi.fetchOrders]        → GET /api/orders
/// - [OrdersApi.fetchOrderDetails]  → GET /api/orders/{id}
/// - [OrdersApi.confirmDelivery]    → POST /api/orders/{id}/confirm-delivery
///
/// **التقييمات [5.8]**
/// - [RatingsApi.submitStoreRating]   → POST /api/stores/{storeId}/ratings
/// - [RatingsApi.submitProductRating] → POST /api/products/{productId}/ratings
/// - [RatingsApi.fetchProductRatings] → GET /api/products/{productId}/ratings
/// - [RatingsApi.fetchStoreRatings]   → GET /api/stores/{storeId}/ratings
///
/// **تقييم الطلب (واجهة موحّدة)**
/// - [OrderRatingsService.rateStore]   — متجر: نجوم فقط
/// - [OrderRatingsService.rateProduct] — منتج: نجوم + تعليق + صورة
class CustomerApi {
  CustomerApi({ApiClient? client})
      : orders = OrdersApi(client: client),
        ratings = RatingsApi(client: client),
        orderRatings = OrderRatingsService(api: RatingsApi(client: client));

  final OrdersApi orders;
  final RatingsApi ratings;
  final OrderRatingsService orderRatings;
}
