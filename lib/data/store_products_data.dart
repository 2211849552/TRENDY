import '../models/product.dart';
import 'product_images.dart';

/// منتجات ملابس لكل متجر — صور ملابس فقط (بدون أحذية أو إكسسوارات).
class StoreProductsData {
  StoreProductsData._();

  static List<Product> productsFor(String storeNameKey) {
    final seeds = _byStore[storeNameKey];
    if (seeds == null) return [];
    return seeds
        .map(
          (s) => Product(
            name: s.name,
            category: s.category,
            price: s.price,
            originalPrice: s.originalPrice,
            rating: s.rating,
            imageUrl: ProductImages.forProductKey(s.name),
            discount: s.discount,
            storeName: storeNameKey,
            isOutOfStock: s.isOutOfStock,
          ),
        )
        .toList();
  }
}

class _Seed {
  final String name;
  final String category;
  final double price;
  final double? originalPrice;
  final double rating;
  final String? discount;
  final bool isOutOfStock;

  const _Seed(
    this.name,
    this.category,
    this.price, {
    this.originalPrice,
    this.rating = 4.5,
    this.discount,
    this.isOutOfStock = false,
  });
}

const Map<String, List<_Seed>> _byStore = {
  'store_elegance': [
    _Seed('prod_wrap_midi_dress', 'cat_dress', 239, originalPrice: 299, rating: 4.7, discount: '-%20'),
    _Seed('prod_maxi_dress_flowy', 'cat_dress', 279, originalPrice: 339, rating: 4.6, discount: '-%18'),
    _Seed('prod_high_waist_trousers', 'cat_other', 179, rating: 4.5),
    _Seed('prod_elegance_pants_2', 'cat_other', 199, originalPrice: 249, rating: 4.4, discount: '-%20'),
    _Seed('prod_striped_button_shirt', 'cat_shirt', 119, originalPrice: 149, rating: 4.4, discount: '-%20'),
    _Seed('prod_satin_blouse', 'cat_shirt', 129, originalPrice: 169, rating: 4.6, discount: '-%24'),
    _Seed('prod_pleated_skirt', 'cat_other', 149, originalPrice: 189, rating: 4.5, discount: '-%21'),
    _Seed('prod_elegance_skirt_2', 'cat_other', 159, rating: 4.4),
    _Seed('prod_linen_blazer', 'cat_other', 319, originalPrice: 399, rating: 4.8, discount: '-%20'),
    _Seed('prod_cotton_cardigan', 'cat_other', 169, rating: 4.3),
  ],
  'store_luxury': [
    _Seed('prod_evening_gown', 'cat_dress', 1290, originalPrice: 1590, rating: 4.8, discount: '-%19'),
    _Seed('prod_lux_midi_dress', 'cat_dress', 990, originalPrice: 1190, rating: 4.7, discount: '-%17'),
    _Seed('prod_lux_tailored_pants', 'cat_other', 520, originalPrice: 650, rating: 4.6, discount: '-%20'),
    _Seed('prod_luxury_pants_2', 'cat_other', 540, rating: 4.5),
    _Seed('prod_lux_silk_blouse', 'cat_shirt', 520, originalPrice: 650, rating: 4.6, discount: '-%20'),
    _Seed('prod_lux_white_blouse', 'cat_shirt', 430, rating: 4.4),
    _Seed('prod_satin_skirt', 'cat_other', 310, originalPrice: 390, rating: 4.4, discount: '-%21'),
    _Seed('prod_luxury_skirt_2', 'cat_other', 330, originalPrice: 410, rating: 4.5, discount: '-%20'),
    _Seed('prod_lux_cashmere_coat', 'cat_other', 1890, originalPrice: 2290, rating: 4.8, discount: '-%17'),
    _Seed('prod_lux_trench_coat', 'cat_other', 1590, originalPrice: 1890, rating: 4.7, discount: '-%16'),
  ],
  'store_gentle': [
    _Seed('prod_gentle_shirt_1', 'cat_gentle_shirt', 189, originalPrice: 229, rating: 4.6, discount: '-%17'),
    _Seed('prod_gentle_shirt_2', 'cat_gentle_shirt', 199, originalPrice: 249, rating: 4.5, discount: '-%20'),
    _Seed('prod_gentle_tshirt_1', 'cat_gentle_tshirt', 79, originalPrice: 99, rating: 4.5, discount: '-%20'),
    _Seed('prod_gentle_tshirt_2', 'cat_gentle_tshirt', 89, originalPrice: 109, rating: 4.4, discount: '-%18'),
    _Seed('prod_gentle_pants_1', 'cat_gentle_pants', 219, rating: 4.5),
    _Seed('prod_gentle_pants_2', 'cat_gentle_pants', 249, originalPrice: 299, rating: 4.4, discount: '-%17'),
    _Seed('prod_gentle_shorts_1', 'cat_gentle_shorts', 99, originalPrice: 129, rating: 4.6, discount: '-%23'),
    _Seed('prod_gentle_shorts_2', 'cat_gentle_shorts', 119, rating: 4.5),
    _Seed('prod_gentle_jacket_1', 'cat_gentle_jacket', 399, originalPrice: 499, rating: 4.6, discount: '-%20'),
    _Seed('prod_gentle_jacket_2', 'cat_gentle_jacket', 289, originalPrice: 359, rating: 4.5, discount: '-%19'),
  ],
  'store_fashion': [
    _Seed('prod_basic_tshirt', 'cat_shirt', 69, originalPrice: 89, rating: 4.5, discount: '-%22'),
    _Seed('prod_denim_jacket_m', 'cat_other', 289, originalPrice: 359, rating: 4.6, discount: '-%20'),
    _Seed('prod_hoodie_fleece', 'cat_shirt', 159, rating: 4.4),
    _Seed('prod_slim_jeans', 'cat_other', 199, originalPrice: 249, rating: 4.5, discount: '-%20'),
    _Seed('prod_relaxed_jeans', 'cat_other', 199, originalPrice: 239, rating: 4.3, discount: '-%17'),
    _Seed('prod_puffer_jacket', 'cat_other', 349, originalPrice: 449, rating: 4.6, discount: '-%22'),
    _Seed('prod_bomber_jacket', 'cat_other', 299, originalPrice: 359, rating: 4.5, discount: '-%16'),
    _Seed('prod_graphic_tee', 'cat_shirt', 79, originalPrice: 99, rating: 4.4, discount: '-%20'),
    _Seed('prod_track_pants', 'cat_other', 129, originalPrice: 159, rating: 4.3, discount: '-%19'),
  ],
  'store_kids': [
    _Seed('prod_kids_dress_cotton', 'cat_dress', 99, originalPrice: 129, rating: 4.6, discount: '-%23'),
    _Seed('prod_kids_dress_party', 'cat_dress', 139, originalPrice: 169, rating: 4.6, discount: '-%18'),
    _Seed('prod_kids_jeans', 'cat_other', 89, rating: 4.5),
    _Seed('prod_kids_pants_2', 'cat_other', 99, originalPrice: 129, rating: 4.4, discount: '-%23'),
    _Seed('prod_kids_shirt_1', 'cat_shirt', 79, originalPrice: 99, rating: 4.7, discount: '-%20'),
    _Seed('prod_kids_shirt_2', 'cat_shirt', 89, rating: 4.6),
    _Seed('prod_kids_skirt_1', 'cat_other', 79, originalPrice: 99, rating: 4.5, discount: '-%20'),
    _Seed('prod_kids_skirt_2', 'cat_other', 89, rating: 4.4),
    _Seed('prod_kids_jacket_light', 'cat_other', 139, rating: 4.4),
    _Seed('prod_kids_jacket_2', 'cat_other', 149, originalPrice: 189, rating: 4.5, discount: '-%21'),
  ],
  'store_top': [
    _Seed('prod_trench_coat', 'cat_other', 449, originalPrice: 549, rating: 4.7, discount: '-%18'),
    _Seed('prod_knit_sweater', 'cat_shirt', 189, originalPrice: 229, rating: 4.6, discount: '-%17'),
    _Seed('prod_oversized_hoodie', 'cat_shirt', 169, rating: 4.5),
    _Seed('prod_long_sleeve_tee', 'cat_shirt', 89, rating: 4.3),
    _Seed('prod_joggers', 'cat_other', 119, rating: 4.3),
    _Seed('prod_windbreaker_jacket', 'cat_other', 239, originalPrice: 289, rating: 4.4, discount: '-%17'),
    _Seed('prod_black_jeans', 'cat_other', 199, originalPrice: 239, rating: 4.4, discount: '-%17'),
    _Seed('prod_sweatshirt_basic', 'cat_shirt', 129, originalPrice: 159, rating: 4.3, discount: '-%19'),
    _Seed('prod_denim_jacket_classic', 'cat_other', 299, originalPrice: 359, rating: 4.5, discount: '-%16'),
  ],
};
