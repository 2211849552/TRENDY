class Product {
  final String name;
  final String category;
  final double price;
  final double? originalPrice;
  final double rating;
  final String imageUrl;
  final String? discount;
  final String storeName;
  final bool isOutOfStock;

  Product({
    required this.name,
    required this.category,
    required this.price,
    this.originalPrice,
    required this.rating,
    required this.imageUrl,
    this.discount,
    required this.storeName,
    this.isOutOfStock = false,
  });
}
