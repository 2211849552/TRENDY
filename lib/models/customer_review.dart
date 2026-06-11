/// تقييم زبون عام يظهر لجميع المشترين لنفس المنتج أو المتجر.
class CustomerReview {
  final String authorName;
  final double rating;
  final String comment;
  final String? imageAssetPath;
  final List<String> imageUrls;
  final DateTime date;

  const CustomerReview({
    required this.authorName,
    required this.rating,
    required this.comment,
    this.imageAssetPath,
    this.imageUrls = const [],
    required this.date,
  });
}
