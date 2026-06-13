import 'api_client.dart';
import 'complaints_api.dart';
import 'notifications_api.dart';
import 'order_ratings_service.dart';
import 'orders_api.dart';
import 'ratings_api.dart';

export 'complaints_api.dart';
export 'customer_api_paths.dart';
export 'notifications_api.dart';
export 'order_ratings_service.dart';
export 'orders_api.dart';
export 'ratings_api.dart';

/// نقطة دخول API تطبيق الزبون — انظر `lib/api.md`:
///
/// **الطلبات [16]**
/// - [OrdersApi.fetchOrders]        → GET /api/orders
/// - [OrdersApi.fetchOrderDetails]  → GET /api/orders/{id}
/// - [OrdersApi.confirmDelivery]    → POST /api/orders/{id}/confirm-delivery { otp }
///
/// **الشكاوى [6]**
/// - [ComplaintsApi.createComplaint] → POST /api/complaints
/// - [ComplaintsApi.fetchComplaint]  → GET /api/complaints/{id}
/// - [ComplaintsApi.addReply]        → POST /api/complaints/{id}/replies
///
/// **الإشعارات [20]**
/// - [NotificationsApi.fetchNotifications] → GET /api/notifications
/// - [NotificationsApi.markAsRead]         → PATCH /api/notifications/{id}/read
/// - [NotificationsApi.markAllAsRead]      → POST /api/notifications/read-all
///
/// **المنتجات [5.3]**
/// - [ProductsApi.fetchProductDetails]   → GET /api/products/{id}
/// - [ProductsApi.fetchProductVariants]  → GET /api/products/{id}/variants (ألوان/مقاسات)
/// - [ProductsApi.fetchStoreProducts]    → GET /api/stores/{storeId}/products
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
        orderRatings = OrderRatingsService(api: RatingsApi(client: client)),
        complaints = ComplaintsApi(client: client),
        notifications = NotificationsApi(client: client);

  final OrdersApi orders;
  final RatingsApi ratings;
  final OrderRatingsService orderRatings;
  final ComplaintsApi complaints;
  final NotificationsApi notifications;
}
