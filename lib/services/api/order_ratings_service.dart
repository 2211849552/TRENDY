import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'ratings_api.dart';

/// إرسال تقييمات الطلب عبر API — انظر `lib/api.md` [5.8].
///
/// - المتجر: POST /api/stores/{storeId}/ratings — `{ "stars": 1..5 }`
/// - المنتج: POST /api/products/{productId}/ratings — نجوم + تعليق + صورة (multipart)
class OrderRatingsService {
  OrderRatingsService({RatingsApi? api}) : _api = api ?? RatingsApi();

  final RatingsApi _api;

  /// تقييم المتجر — نجوم فقط (بدون صور).
  Future<void> rateStore({
    required int storeId,
    required int stars,
  }) async {
    final safe = stars.clamp(1, 5);
    await _api.submitStoreRating(storeId, stars: safe);
  }

  /// تقييم منتج — نجوم + رسالة اختيارية + صورة واحدة اختيارية.
  Future<void> rateProduct({
    required int productId,
    required int stars,
    String? comment,
    http.MultipartFile? imageFile,
  }) async {
    final safe = stars.clamp(1, 5);
    if (imageFile != null && imageFile.length > 5 * 1024 * 1024) {
      throw ApiException('حجم الصورة يتجاوز 5 ميجابايت');
    }
    await _api.submitProductRating(
      productId,
      stars: safe,
      comment: comment,
      imageFile: imageFile,
    );
  }
}
