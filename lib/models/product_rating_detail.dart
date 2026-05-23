/// تفاصيل تقييم منتج (نجوم + تعليق وصور اختيارية).
class ProductRatingDetail {
  final double rating;
  final String? comment;
  final List<String> imagePaths;

  const ProductRatingDetail({
    required this.rating,
    this.comment,
    this.imagePaths = const [],
  });
}
