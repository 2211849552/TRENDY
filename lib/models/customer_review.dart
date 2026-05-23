/// تقييم زبون عام يظهر لجميع المشترين لنفس المنتج.
class CustomerReview {
  final String authorName;
  final double rating;
  final String comment;
  final String? imageAssetPath;
  final DateTime date;

  const CustomerReview({
    required this.authorName,
    required this.rating,
    required this.comment,
    this.imageAssetPath,
    required this.date,
  });
}
