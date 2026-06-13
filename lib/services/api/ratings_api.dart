import 'package:http/http.dart' as http;

import '../../models/customer_review.dart';
import 'api_client.dart';
import 'customer_api_paths.dart';
import 'media_url.dart';

class ApiRating {
  const ApiRating({
    required this.id,
    required this.stars,
    required this.comment,
    required this.authorName,
    this.authorId,
    this.imageUrl,
    this.imageUrls = const [],
    this.createdAt,
  });

  final int id;
  final int stars;
  final String comment;
  final String authorName;
  final int? authorId;
  final String? imageUrl;
  final List<String> imageUrls;
  final DateTime? createdAt;

  CustomerReview toCustomerReview() {
    final images = imageUrls.isNotEmpty
        ? imageUrls
        : (imageUrl != null && imageUrl!.isNotEmpty ? [imageUrl!] : const <String>[]);
    return CustomerReview(
      authorName: authorName,
      rating: stars.toDouble(),
      comment: comment,
      imageAssetPath: images.isNotEmpty ? images.first : null,
      imageUrls: images,
      date: createdAt ?? DateTime.now(),
    );
  }

  factory ApiRating.fromJson(Map<String, dynamic> json) {
    final ratingId = _asInt(json['id']) ?? 0;

    final user = json['user'];
    var author = '';
    int? authorId;
    if (user is Map) {
      author = '${user['name'] ?? ''}'.trim();
      authorId = _asInt(user['id']);
    }

    final urls = MediaUrl.ratingImagesFromJson(json['images'], ratingId: ratingId);

    var imageUrl = MediaUrl.ratingImage(json['image'], ratingId: ratingId);
    if (imageUrl.isEmpty && urls.isNotEmpty) imageUrl = urls.first;
    if (imageUrl.isNotEmpty && !urls.contains(imageUrl)) {
      urls.insert(0, imageUrl);
    }

    return ApiRating(
      id: ratingId,
      stars: _asInt(json['stars']) ?? 0,
      comment: '${json['comment'] ?? ''}'.trim(),
      authorName: author.isNotEmpty ? author : '—',
      authorId: authorId,
      imageUrl: imageUrl.isEmpty ? null : imageUrl,
      imageUrls: urls,
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }
}

class RatingsPageResult {
  const RatingsPageResult({
    required this.ratings,
    required this.averageRating,
    required this.totalRatings,
    required this.currentPage,
    required this.lastPage,
  });

  final List<ApiRating> ratings;
  final double averageRating;
  final int totalRatings;
  final int currentPage;
  final int lastPage;

  bool get hasMore => currentPage < lastPage;
}

/// تقييمات المتجر والمنتج — انظر `lib/api.md` قسم [5.8] و [CustomerApiPaths].
class RatingsApi {
  RatingsApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<RatingsPageResult> fetchProductRatings(
    int productId, {
    int page = 1,
    int perPage = 20,
  }) {
    return _fetch(CustomerApiPaths.productRatings(productId), page: page, perPage: perPage);
  }

  Future<RatingsPageResult> fetchStoreRatings(
    int storeId, {
    int page = 1,
    int perPage = 20,
  }) {
    return _fetch(CustomerApiPaths.storeRatings(storeId), page: page, perPage: perPage);
  }

  /// POST /api/stores/{storeId}/ratings — نجوم (± تعليق اختياري، بدون صور).
  Future<void> submitStoreRating(
    int storeId, {
    required int stars,
    String? comment,
  }) async {
    await _client.postFromRoot(
      CustomerApiPaths.storeRatings(storeId),
      body: {
        'stars': stars,
        if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
      },
    );
  }

  /// POST /api/products/{productId}/ratings — نجوم + تعليق + صورة/صور اختيارية.
  Future<void> submitProductRating(
    int productId, {
    required int stars,
    String? comment,
    List<http.MultipartFile> imageFiles = const [],
  }) async {
    final trimmedComment = comment?.trim();
    if (imageFiles.isNotEmpty) {
      await _client.postMultipartFromRoot(
        CustomerApiPaths.productRatings(productId),
        fields: {
          'stars': '$stars',
          if (trimmedComment != null && trimmedComment.isNotEmpty) 'comment': trimmedComment,
        },
        files: imageFiles,
      );
      return;
    }

    await _client.postFromRoot(
      CustomerApiPaths.productRatings(productId),
      body: {
        'stars': stars,
        if (trimmedComment != null && trimmedComment.isNotEmpty) 'comment': trimmedComment,
      },
    );
  }

  Future<RatingsPageResult> _fetch(
    String path, {
    required int page,
    required int perPage,
  }) async {
    final json = await _client.getFromRoot(
      path,
      withAuth: false,
      query: {'page': '$page', 'per_page': '$perPage'},
    );

    final ratingsBlock = json['ratings'];
    final rows = ratingsBlock is Map ? ratingsBlock['data'] : null;
    final meta = ratingsBlock is Map ? ratingsBlock['meta'] : null;

    final list = <ApiRating>[];
    if (rows is List) {
      for (final row in rows) {
        if (row is Map<String, dynamic>) list.add(ApiRating.fromJson(row));
      }
    }

    return RatingsPageResult(
      ratings: list,
      averageRating: _asDouble(json['average_rating']) ?? 0,
      totalRatings: _asInt(json['total_ratings']) ?? list.length,
      currentPage: meta is Map ? (_asInt(meta['current_page']) ?? page) : page,
      lastPage: meta is Map ? (_asInt(meta['last_page']) ?? 1) : 1,
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }
}
