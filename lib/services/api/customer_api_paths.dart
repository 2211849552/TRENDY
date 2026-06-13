/// مسارات API المستخدمة في تطبيق الزبون (Flutter).
/// المصدر: [lib/api.md] — أقسام [5]، [6]، [16]، [20].
class CustomerApiPaths {
  CustomerApiPaths._();

  // ─── [6] الشكاوى ────────────────────────────────────────────────────────
  /// POST /api/complaints — فتح شكوى (زبون)
  static const complaints = '/complaints';

  /// GET /api/complaints/{id} — تفاصيل شكوى
  static String complaint(int id) => '/complaints/$id';

  /// POST /api/complaints/{id}/replies — إضافة رد
  static String complaintReplies(int id) => '/complaints/$id/replies';

  // ─── [20] الإشعارات ─────────────────────────────────────────────────────
  /// GET /api/notifications — قائمة الإشعارات
  static const notifications = '/notifications';

  /// POST /api/notifications/read-all — تحديد الكل كمقروء
  static const notificationsReadAll = '/notifications/read-all';

  /// GET /api/notifications/{id} — تفاصيل إشعار
  static String notification(int id) => '/notifications/$id';

  /// PATCH /api/notifications/{id}/read — تحديد إشعار كمقروء
  static String notificationRead(int id) => '/notifications/$id/read';

  // ─── [16] الطلبات ───────────────────────────────────────────────────────
  /// GET /api/orders — قائمة طلبات الزبون
  static const orders = '/orders';

  /// GET /api/orders/{id} — تفاصيل طلب
  static String order(int id) => '/orders/$id';

  /// POST /api/orders/{id}/confirm-delivery — تأكيد استلام الطلبية
  /// Body: `{ "otp": "123456" }` — انظر api.md [16.7]
  static String orderConfirmDelivery(int id) => '/orders/$id/confirm-delivery';

  // ─── [5.8] التقييمات ────────────────────────────────────────────────────
  /// POST /api/stores/{storeId}/ratings — تقييم المتجر (نجوم ± تعليق)
  /// GET  /api/stores/{storeId}/ratings — عرض تقييمات المتجر
  static String storeRatings(int storeId) => '/stores/$storeId/ratings';

  /// POST /api/products/{productId}/ratings — تقييم منتج (نجوم + تعليق + صورة)
  /// GET  /api/products/{productId}/ratings — عرض تقييمات المنتج
  static String productRatings(int productId) => '/products/$productId/ratings';

  // ─── [5.3] صور المنتجات (إثراء عناصر الطلب/السلة) ───────────────────────
  /// GET /api/products/{id} — تفاصيل منتج: `thumbnail`, `images[]`
  static String product(int id) => '/products/$id';

  /// GET /api/products/{id}/variants — ألوان ومقاسات التنوعات المتوفرة [5.3]
  static String productVariants(int id) => '/products/$id/variants';

  /// GET /api/stores/{storeId}/products — بحث منتجات المتجر (`thumbnail`)
  static String storeProducts(int storeId) => '/stores/$storeId/products';

  /// GET /api/products/search — بحث عام بالاسم
  static const productSearch = '/products/search';
}
