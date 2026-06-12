/// مسارات API المستخدمة في تطبيق الزبون (Flutter).
/// المصدر: [lib/api.md] — أقسام [5] المنتجات، [5.8] التقييمات، [16] الطلبات.
class CustomerApiPaths {
  CustomerApiPaths._();

  // ─── [16] الطلبات ───────────────────────────────────────────────────────
  /// GET /api/orders — قائمة طلبات الزبون
  static const orders = '/orders';

  /// GET /api/orders/{id} — تفاصيل طلب
  static String order(int id) => '/orders/$id';

  /// POST /api/orders/{id}/confirm-delivery — تأكيد استلام الطلبية
  /// الأدوار: driver, store_manager, store_staff (الزبون: محاكاة محلية عند 403)
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

  /// GET /api/stores/{storeId}/products — بحث منتجات المتجر (`thumbnail`)
  static String storeProducts(int storeId) => '/stores/$storeId/products';

  /// GET /api/products/search — بحث عام بالاسم
  static const productSearch = '/products/search';
}
