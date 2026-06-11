class Product {
  final int? id;
  final int? storeId;
  final String name;
  final String? code;
  final String category;
  final double price;
  final double? originalPrice;
  final double rating;
  final String imageUrl;
  final List<String> imageUrls;
  final String? discount;
  final String storeName;
  final bool isOutOfStock;
  final int? stockQuantity;
  final String? description;

  Product({
    this.id,
    this.storeId,
    required this.name,
    this.code,
    required this.category,
    required this.price,
    this.originalPrice,
    required this.rating,
    required this.imageUrl,
    this.imageUrls = const [],
    this.discount,
    required this.storeName,
    this.isOutOfStock = false,
    this.stockQuantity,
    this.description,
  });

  Product copyWith({
    int? id,
    int? storeId,
    String? name,
    String? code,
    String? category,
    double? price,
    double? originalPrice,
    double? rating,
    String? imageUrl,
    List<String>? imageUrls,
    String? discount,
    String? storeName,
    bool? isOutOfStock,
    int? stockQuantity,
    String? description,
  }) {
    return Product(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      code: code ?? this.code,
      category: category ?? this.category,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      rating: rating ?? this.rating,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      discount: discount ?? this.discount,
      storeName: storeName ?? this.storeName,
      isOutOfStock: isOutOfStock ?? this.isOutOfStock,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      description: description ?? this.description,
    );
  }
}
