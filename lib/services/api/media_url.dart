import '../../config/api_config.dart';

/// بناء روابط صور API — انظر `lib/api.md` قسم «صور عناصر الطلب».
///
/// - المتجر: `logo` من GET /api/stores
/// - الحملة: `banner_image` من GET /api/campaigns
/// - المنتج (طلب/سلة/تقييم): `thumbnail`, `images[]`, `image`
///   مع تصحيح مسار `storage/products/{productId}/` عبر GET /api/products/{id}
class MediaUrl {
  MediaUrl._();

  static String storeLogo(dynamic raw) => ApiConfig.resolveMediaUrl(_asString(raw));

  static String productThumbnail(dynamic raw, {int? productId}) =>
      productImage(raw, productId: productId);

  /// رابط صورة منتج واحدة مع تصحيح مسار التخزين.
  static String productImage(dynamic raw, {int? productId}) {
    final resolved = ApiConfig.resolveMediaUrl(_asString(raw));
    if (resolved.isEmpty) return '';
    return _fixProductStoragePath(resolved, productId);
  }

  /// استخراج كل روابط `images[]` من تفاصيل المنتج.
  static List<String> productImagesFromJson(dynamic raw, {int? productId}) {
    if (raw is! List) return const [];
    final urls = <String>[];
    for (final item in raw) {
      if (item is Map) {
        final url = productImage(item['url'] ?? item['file_name'], productId: productId);
        if (url.isNotEmpty) urls.add(url);
      }
    }
    return urls;
  }

  /// رابط صورة تقييم منتج — Laravel يُخزّن في `ratings/{ratingId}/` لكن API يُرجع `storage/{file}` فقط.
  static String ratingImage(dynamic raw, {required int ratingId}) {
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final original = map['original_url']?.toString();
      if (original != null && original.trim().isNotEmpty) {
        return _fixRatingStoragePath(ApiConfig.resolveMediaUrl(original), ratingId);
      }
      final fileName = '${map['file_name'] ?? map['url'] ?? ''}'.trim();
      if (fileName.isNotEmpty) {
        return ratingImage(fileName, ratingId: ratingId);
      }
      return '';
    }

    final resolved = ApiConfig.resolveMediaUrl(_asString(raw));
    if (resolved.isEmpty) return '';
    return _fixRatingStoragePath(resolved, ratingId);
  }

  static List<String> ratingImagesFromJson(dynamic raw, {required int ratingId}) {
    if (raw is! List) return const [];
    final urls = <String>[];
    for (final item in raw) {
      final url = ratingImage(item, ratingId: ratingId);
      if (url.isNotEmpty) urls.add(url);
    }
    return urls;
  }

  static String _fixRatingStoragePath(String url, int ratingId) {
    if (ratingId <= 0) return url;
    if (url.contains('/storage/ratings/')) return url;

    final fileName = _extractStorageFileName(url);
    if (fileName == null || fileName.isEmpty) return url;
    return '${ApiConfig.serverOrigin}/storage/ratings/$ratingId/$fileName';
  }

  /// Laravel يُخزّن الصور في `products/{id}/` لكن API يُرجع `storage/{file}` فقط.
  static String _fixProductStoragePath(String url, int? productId) {
    if (productId == null || productId <= 0) return url;
    if (url.contains('/storage/products/')) return url;

    final fileName = _extractStorageFileName(url);
    if (fileName == null || fileName.isEmpty) return url;
    return '${ApiConfig.serverOrigin}/storage/products/$productId/$fileName';
  }

  static String? _extractStorageFileName(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;

    final storageIdx = trimmed.indexOf('/storage/');
    if (storageIdx == -1) {
      if (trimmed.contains('/') || !trimmed.contains('.')) return null;
      return trimmed;
    }

    final afterStorage = trimmed.substring(storageIdx + '/storage/'.length);
    if (afterStorage.startsWith('products/')) return null;
    if (afterStorage.contains('/')) return afterStorage.split('/').last;
    return afterStorage;
  }

  static String? campaignBanner(dynamic raw) {
    final url = ApiConfig.resolveMediaUrl(_asString(raw));
    return url.isEmpty ? null : url;
  }

  static String _asString(dynamic value) => '${value ?? ''}'.trim();
}
