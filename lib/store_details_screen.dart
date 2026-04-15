import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'l10n/app_strings.dart';
import 'models/product.dart';
import 'models/ratings_manager.dart';
import 'services/store_location.dart';
import 'product_details_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chat/chat_with_store_screen.dart';
import 'widgets/app_back_button.dart';

class StoreDetailsScreen extends StatefulWidget {
  final String storeName;
  final String storeCategory;
  final double storeRating;
  final String storeDistance;
  final String storeImageUrl;
  final String? storeDiscount;
  final StoreLocation? storeLocation;

  const StoreDetailsScreen({
    super.key,
    required this.storeName,
    required this.storeCategory,
    required this.storeRating,
    required this.storeDistance,
    required this.storeImageUrl,
    this.storeDiscount,
    this.storeLocation,
  });

  @override
  State<StoreDetailsScreen> createState() => _StoreDetailsScreenState();
}

class _StoreDetailsScreenState extends State<StoreDetailsScreen> {
  final RatingsManager _ratingsManager = RatingsManager();
  String _selectedCategory = 'cat_all';
  RangeValues _priceRange = const RangeValues(0, 1500);
  String _selectedRating = 'all_ratings';
  String _selectedAvailability = 'all_availability';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late final List<Product> _allProducts;
  bool _openingMap = false;

  Future<void> _openInGoogleMaps() async {
    final loc = widget.storeLocation;
    if (loc == null) return;
    setState(() => _openingMap = true);
    try {
      final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${loc.lat},${loc.lng}&travelmode=driving',
      );
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('map_open_failed'), style: GoogleFonts.cairo())),
        );
      }
    } finally {
      if (mounted) setState(() => _openingMap = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _allProducts = _getMockProducts(widget.storeCategory, widget.storeName, widget.storeDiscount != null);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _getMockProducts(String storeCat, String storeNameKey, bool hasStoreDiscount) {
    List<Product> products = _generateRawProducts(storeCat, storeNameKey);
    
    if (!hasStoreDiscount) {
      return products.map((p) => Product(
        name: p.name,
        code: p.code ?? _buildProductCode(p.name),
        category: p.category,
        price: p.price,
        originalPrice: null,
        rating: p.rating,
        imageUrl: p.imageUrl,
        discount: null,
        storeName: p.storeName,
        isOutOfStock: p.isOutOfStock,
      )).toList();
    }
    return products
        .map(
          (p) => Product(
            name: p.name,
            code: p.code ?? _buildProductCode(p.name),
            category: p.category,
            price: p.price,
            originalPrice: p.originalPrice,
            rating: p.rating,
            imageUrl: p.imageUrl,
            discount: p.discount,
            storeName: p.storeName,
            isOutOfStock: p.isOutOfStock,
          ),
        )
        .toList();
  }

  String _buildProductCode(String key) {
    return key.replaceFirst('prod_', '').replaceAll('_', '-').toUpperCase();
  }

  /// Returns a type-matching product image from Unsplash.
  /// Uses `sig` so each product gets a different image.
  String _img(String query, int sig) {
    final q = query.trim().replaceAll(' ', '-');
    return 'https://source.unsplash.com/featured/900x900/?$q&sig=$sig';
  }

  List<Product> _generateRawProducts(String storeCat, String storeNameKey) {
    // 1. متجر الأناقة (Women - everyday)
    if (storeNameKey == 'store_elegance') {
      return [
        Product(
          name: 'prod_wrap_midi_dress',
          category: 'cat_dress',
          price: 239,
          originalPrice: 299,
          rating: 4.7,
          imageUrl: _img('wrap dress', 1),
          discount: '-%20',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_satin_blouse',
          category: 'cat_shirt',
          price: 129,
          originalPrice: 169,
          rating: 4.6,
          imageUrl: _img('satin blouse', 2),
          discount: '-%24',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_high_waist_trousers',
          category: 'cat_other',
          price: 179,
          originalPrice: null,
          rating: 4.5,
          imageUrl: _img('high waist trousers', 3),
          discount: null,
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_linen_blazer',
          category: 'cat_other',
          price: 319,
          originalPrice: 399,
          rating: 4.8,
          imageUrl: _img('linen blazer women', 4),
          discount: '-%20',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_white_sneakers_w',
          category: 'cat_shoe',
          price: 199,
          originalPrice: null,
          rating: 4.7,
          imageUrl: _img('white sneakers', 5),
          discount: null,
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_tote_bag',
          category: 'cat_accessories',
          price: 99,
          originalPrice: 129,
          rating: 4.4,
          imageUrl: _img('tote bag', 6),
          discount: '-%23',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_soft_hijab_scarf',
          category: 'cat_accessories',
          price: 49,
          originalPrice: null,
          rating: 4.6,
          imageUrl: _img('hijab scarf', 7),
          discount: null,
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_denim_jacket_w',
          category: 'cat_other',
          price: 259,
          originalPrice: 319,
          rating: 4.5,
          imageUrl: _img('denim jacket women', 8),
          discount: '-%19',
          storeName: storeNameKey,
          isOutOfStock: true,
        ),
        Product(
          name: 'prod_ribbed_knit_top',
          category: 'cat_shirt',
          price: 89,
          originalPrice: 109,
          rating: 4.4,
          imageUrl: _img('ribbed knit top', 9),
          discount: '-%18',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_pleated_skirt',
          category: 'cat_other',
          price: 149,
          originalPrice: 189,
          rating: 4.5,
          imageUrl: _img('pleated skirt', 10),
          discount: '-%21',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_cotton_cardigan',
          category: 'cat_other',
          price: 169,
          originalPrice: null,
          rating: 4.3,
          imageUrl: _img('cotton cardigan', 11),
          discount: null,
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_black_ankle_boots',
          category: 'cat_shoe',
          price: 229,
          originalPrice: 279,
          rating: 4.6,
          imageUrl: _img('black ankle boots', 12),
          discount: '-%18',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_maxi_dress_flowy',
          category: 'cat_dress',
          price: 279,
          originalPrice: 339,
          rating: 4.6,
          imageUrl: _img('maxi dress', 13),
          discount: '-%18',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_striped_button_shirt',
          category: 'cat_shirt',
          price: 119,
          originalPrice: 149,
          rating: 4.4,
          imageUrl: _img('striped shirt', 14),
          discount: '-%20',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_wide_leg_pants',
          category: 'cat_other',
          price: 189,
          originalPrice: null,
          rating: 4.5,
          imageUrl: _img('wide leg pants', 15),
          discount: null,
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_knit_cardigan_long',
          category: 'cat_other',
          price: 199,
          originalPrice: 239,
          rating: 4.3,
          imageUrl: _img('long cardigan', 16),
          discount: '-%17',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_ballet_flats',
          category: 'cat_shoe',
          price: 129,
          originalPrice: null,
          rating: 4.2,
          imageUrl: _img('ballet flats shoes', 17),
          discount: null,
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_denim_skirt_new',
          category: 'cat_other',
          price: 139,
          originalPrice: 169,
          rating: 4.4,
          imageUrl: _img('denim skirt', 18),
          discount: '-%18',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_leather_crossbody_w',
          category: 'cat_accessories',
          price: 119,
          originalPrice: 149,
          rating: 4.3,
          imageUrl: _img('leather crossbody bag', 19),
          discount: '-%20',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_sport_set_w',
          category: 'cat_other',
          price: 249,
          originalPrice: 299,
          rating: 4.5,
          imageUrl: _img('women tracksuit', 20),
          discount: '-%17',
          storeName: storeNameKey,
          isOutOfStock: true,
        ),
      ];
    }

    // 2. متجر الفخامة (Women - premium)
    if (storeNameKey == 'store_luxury') {
      return [
        Product(
          name: 'prod_evening_gown',
          category: 'cat_dress',
          price: 1290,
          originalPrice: 1590,
          rating: 4.8,
          imageUrl: _img('evening gown', 21),
          discount: '-%19',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_silk_set',
          category: 'cat_other',
          price: 740,
          originalPrice: 920,
          rating: 4.7,
          imageUrl: _img('silk outfit', 22),
          discount: '-%20',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_leather_heels',
          category: 'cat_shoe',
          price: 560,
          originalPrice: 690,
          rating: 4.6,
          imageUrl: _img('leather high heels', 23),
          discount: '-%18',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_mini_clutch',
          category: 'cat_accessories',
          price: 420,
          originalPrice: null,
          rating: 4.5,
          imageUrl: _img('clutch bag', 24),
          discount: null,
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_pearl_earrings',
          category: 'cat_accessories',
          price: 290,
          originalPrice: 350,
          rating: 4.6,
          imageUrl: _img('pearl earrings', 25),
          discount: '-%17',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_signature_blazer',
          category: 'cat_other',
          price: 980,
          originalPrice: null,
          rating: 4.7,
          imageUrl: _img('designer blazer', 26),
          discount: null,
          storeName: storeNameKey,
          isOutOfStock: true,
        ),
        Product(
          name: 'prod_satin_skirt',
          category: 'cat_other',
          price: 310,
          originalPrice: 390,
          rating: 4.4,
          imageUrl: _img('satin skirt', 27),
          discount: '-%21',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_lux_perfume_pouch',
          category: 'cat_accessories',
          price: 210,
          originalPrice: null,
          rating: 4.3,
          imageUrl: _img('small leather pouch', 28),
          discount: null,
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_lux_cashmere_coat',
          category: 'cat_other',
          price: 1890,
          originalPrice: 2290,
          rating: 4.8,
          imageUrl: _img('cashmere coat', 29),
          discount: '-%17',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_lux_silk_blouse',
          category: 'cat_shirt',
          price: 520,
          originalPrice: 650,
          rating: 4.6,
          imageUrl: _img('silk blouse', 30),
          discount: '-%20',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_lux_leather_bag',
          category: 'cat_accessories',
          price: 980,
          originalPrice: null,
          rating: 4.7,
          imageUrl: _img('luxury leather bag', 31),
          discount: null,
          storeName: storeNameKey,
          isOutOfStock: true,
        ),
        Product(
          name: 'prod_lux_stiletto_heels',
          category: 'cat_shoe',
          price: 690,
          originalPrice: 820,
          rating: 4.6,
          imageUrl: _img('stiletto heels', 32),
          discount: '-%16',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_lux_midi_dress',
          category: 'cat_dress',
          price: 990,
          originalPrice: 1190,
          rating: 4.7,
          imageUrl: _img('midi dress luxury', 33),
          discount: '-%17',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_lux_tailored_pants',
          category: 'cat_other',
          price: 520,
          originalPrice: 650,
          rating: 4.6,
          imageUrl: _img('tailored pants women', 34),
          discount: '-%20',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_lux_handbag',
          category: 'cat_accessories',
          price: 1390,
          originalPrice: null,
          rating: 4.8,
          imageUrl: _img('luxury handbag', 35),
          discount: null,
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_lux_silk_scarf',
          category: 'cat_accessories',
          price: 260,
          originalPrice: 320,
          rating: 4.5,
          imageUrl: _img('silk scarf', 36),
          discount: '-%19',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_lux_gold_bracelet',
          category: 'cat_accessories',
          price: 480,
          originalPrice: 590,
          rating: 4.6,
          imageUrl: _img('gold bracelet jewelry', 37),
          discount: '-%19',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_lux_trench_coat',
          category: 'cat_other',
          price: 1590,
          originalPrice: 1890,
          rating: 4.7,
          imageUrl: _img('trench coat luxury', 38),
          discount: '-%16',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_lux_satin_heels',
          category: 'cat_shoe',
          price: 750,
          originalPrice: 880,
          rating: 4.5,
          imageUrl: _img('satin heels', 39),
          discount: '-%15',
          storeName: storeNameKey,
          isOutOfStock: true,
        ),
        Product(
          name: 'prod_lux_white_blouse',
          category: 'cat_shirt',
          price: 430,
          originalPrice: null,
          rating: 4.4,
          imageUrl: _img('white blouse', 40),
          discount: null,
          storeName: storeNameKey,
        ),
      ];
    }

    // 3. الرجل الأنيق (Men - formal)
    if (storeNameKey == 'store_gentle') {
      return [
        Product(
          name: 'prod_wool_suit',
          category: 'cat_other',
          price: 1190,
          originalPrice: 1490,
          rating: 4.7,
          imageUrl: _img('mens suit', 41),
          discount: '-%20',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_oxford_shirt',
          category: 'cat_shirt',
          price: 199,
          originalPrice: 249,
          rating: 4.6,
          imageUrl: _img('oxford shirt men', 42),
          discount: '-%20',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_slim_chinos',
          category: 'cat_other',
          price: 219,
          originalPrice: null,
          rating: 4.5,
          imageUrl: _img('chinos pants men', 43),
          discount: null,
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_leather_oxfords',
          category: 'cat_shoe',
          price: 499,
          originalPrice: 599,
          rating: 4.6,
          imageUrl: _img('leather oxford shoes', 44),
          discount: '-%17',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_silk_tie_modern',
          category: 'cat_accessories',
          price: 119,
          originalPrice: 149,
          rating: 4.4,
          imageUrl: _img('silk tie', 45),
          discount: '-%20',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_leather_belt_classic',
          category: 'cat_accessories',
          price: 95,
          originalPrice: null,
          rating: 4.3,
          imageUrl: _img('leather belt', 46),
          discount: null,
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_wool_overcoat',
          category: 'cat_other',
          price: 790,
          originalPrice: 990,
          rating: 4.7,
          imageUrl: _img('wool overcoat men', 47),
          discount: '-%20',
          storeName: storeNameKey,
          isOutOfStock: true,
        ),
        Product(
          name: 'prod_cufflinks_minimal',
          category: 'cat_accessories',
          price: 79,
          originalPrice: 99,
          rating: 4.2,
          imageUrl: _img('cufflinks', 48),
          discount: '-%20',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_polo_knit',
          category: 'cat_shirt',
          price: 149,
          originalPrice: 179,
          rating: 4.4,
          imageUrl: _img('knit polo shirt', 49),
          discount: '-%17',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_suit_vest',
          category: 'cat_other',
          price: 229,
          originalPrice: 279,
          rating: 4.3,
          imageUrl: _img('suit vest', 50),
          discount: '-%18',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_leather_loafers',
          category: 'cat_shoe',
          price: 399,
          originalPrice: null,
          rating: 4.5,
          imageUrl: _img('leather loafers', 51),
          discount: null,
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_wrist_watch_classic',
          category: 'cat_accessories',
          price: 590,
          originalPrice: 690,
          rating: 4.6,
          imageUrl: _img('classic wristwatch', 52),
          discount: '-%14',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_navy_blazer',
          category: 'cat_other',
          price: 599,
          originalPrice: 749,
          rating: 4.6,
          imageUrl: _img('navy blazer men', 53),
          discount: '-%20',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_formal_pants',
          category: 'cat_other',
          price: 249,
          originalPrice: 299,
          rating: 4.4,
          imageUrl: _img('formal trousers men', 54),
          discount: '-%17',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_white_shirt_formal',
          category: 'cat_shirt',
          price: 179,
          originalPrice: null,
          rating: 4.5,
          imageUrl: _img('white dress shirt', 55),
          discount: null,
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_knit_sweater_men',
          category: 'cat_shirt',
          price: 219,
          originalPrice: 269,
          rating: 4.3,
          imageUrl: _img('mens knit sweater', 56),
          discount: '-%19',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_loafer_suede',
          category: 'cat_shoe',
          price: 429,
          originalPrice: 499,
          rating: 4.5,
          imageUrl: _img('suede loafers', 57),
          discount: '-%14',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_leather_wallet',
          category: 'cat_accessories',
          price: 89,
          originalPrice: 109,
          rating: 4.2,
          imageUrl: _img('leather wallet', 58),
          discount: '-%18',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_belt_buckle',
          category: 'cat_accessories',
          price: 109,
          originalPrice: null,
          rating: 4.1,
          imageUrl: _img('belt buckle', 59),
          discount: null,
          storeName: storeNameKey,
          isOutOfStock: true,
        ),
        Product(
          name: 'prod_wool_scarf_men',
          category: 'cat_accessories',
          price: 69,
          originalPrice: 89,
          rating: 4.3,
          imageUrl: _img('wool scarf men', 60),
          discount: '-%22',
          storeName: storeNameKey,
        ),
      ];
    }

    // 4. بوتيك الموضة (Men - casual / streetwear)
    if (storeNameKey == 'store_fashion') {
      return [
        Product(
          name: 'prod_basic_tshirt',
          category: 'cat_shirt',
          price: 69,
          originalPrice: 89,
          rating: 4.5,
          imageUrl: _img('basic t shirt', 61),
          discount: '-%22',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_denim_jacket_m',
          category: 'cat_other',
          price: 289,
          originalPrice: 359,
          rating: 4.6,
          imageUrl: _img('mens denim jacket', 62),
          discount: '-%20',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_hoodie_fleece',
          category: 'cat_shirt',
          price: 159,
          originalPrice: null,
          rating: 4.4,
          imageUrl: _img('fleece hoodie', 63),
          discount: null,
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_slim_jeans',
          category: 'cat_other',
          price: 199,
          originalPrice: 249,
          rating: 4.5,
          imageUrl: _img('slim jeans men', 64),
          discount: '-%20',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_running_sneakers',
          category: 'cat_shoe',
          price: 279,
          originalPrice: 329,
          rating: 4.7,
          imageUrl: _img('running sneakers', 65),
          discount: '-%15',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_cap_basic',
          category: 'cat_accessories',
          price: 39,
          originalPrice: null,
          rating: 4.2,
          imageUrl: _img('baseball cap', 66),
          discount: null,
          storeName: storeNameKey,
          isOutOfStock: true,
        ),
        Product(
          name: 'prod_crossbody_bag',
          category: 'cat_accessories',
          price: 89,
          originalPrice: 119,
          rating: 4.3,
          imageUrl: _img('crossbody bag', 67),
          discount: '-%25',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_puffer_jacket',
          category: 'cat_other',
          price: 349,
          originalPrice: 449,
          rating: 4.6,
          imageUrl: _img('puffer jacket', 68),
          discount: '-%22',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_overshirt_flannel',
          category: 'cat_shirt',
          price: 179,
          originalPrice: 219,
          rating: 4.4,
          imageUrl: _img('flannel overshirt', 69),
          discount: '-%18',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_cargo_pants',
          category: 'cat_other',
          price: 209,
          originalPrice: null,
          rating: 4.3,
          imageUrl: _img('cargo pants', 70),
          discount: null,
          storeName: storeNameKey,
          isOutOfStock: true,
        ),
        Product(
          name: 'prod_zip_sweatshirt',
          category: 'cat_shirt',
          price: 139,
          originalPrice: 169,
          rating: 4.2,
          imageUrl: _img('zip sweatshirt', 71),
          discount: '-%18',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_skate_sneakers',
          category: 'cat_shoe',
          price: 259,
          originalPrice: 299,
          rating: 4.6,
          imageUrl: _img('skate sneakers', 72),
          discount: '-%13',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_graphic_tee',
          category: 'cat_shirt',
          price: 79,
          originalPrice: 99,
          rating: 4.4,
          imageUrl: _img('graphic t shirt', 73),
          discount: '-%20',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_bomber_jacket',
          category: 'cat_other',
          price: 299,
          originalPrice: 359,
          rating: 4.5,
          imageUrl: _img('bomber jacket', 74),
          discount: '-%16',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_relaxed_jeans',
          category: 'cat_other',
          price: 199,
          originalPrice: 239,
          rating: 4.3,
          imageUrl: _img('relaxed jeans', 75),
          discount: '-%17',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_henley_top',
          category: 'cat_shirt',
          price: 99,
          originalPrice: null,
          rating: 4.2,
          imageUrl: _img('henley shirt', 76),
          discount: null,
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_bucket_hat',
          category: 'cat_accessories',
          price: 29,
          originalPrice: 39,
          rating: 4.1,
          imageUrl: _img('bucket hat', 77),
          discount: '-%26',
          storeName: storeNameKey,
          isOutOfStock: true,
        ),
        Product(
          name: 'prod_sling_bag',
          category: 'cat_accessories',
          price: 69,
          originalPrice: 89,
          rating: 4.2,
          imageUrl: _img('sling bag', 78),
          discount: '-%22',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_track_pants',
          category: 'cat_other',
          price: 129,
          originalPrice: 159,
          rating: 4.3,
          imageUrl: _img('track pants', 79),
          discount: '-%19',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_crew_socks',
          category: 'cat_accessories',
          price: 15,
          originalPrice: null,
          rating: 4.0,
          imageUrl: _img('crew socks', 80),
          discount: null,
          storeName: storeNameKey,
        ),
      ];
    }

    // 5. عالم الأطفال (Kids - clothing)
    if (storeNameKey == 'store_kids') {
      return [
        Product(
          name: 'prod_kids_hoodie',
          category: 'cat_shirt',
          price: 79,
          originalPrice: 99,
          rating: 4.7,
          imageUrl: _img('kids hoodie', 81),
          discount: '-%20',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_kids_denim',
          category: 'cat_other',
          price: 89,
          originalPrice: null,
          rating: 4.5,
          imageUrl: _img('kids jeans', 82),
          discount: null,
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_kids_sneakers',
          category: 'cat_shoe',
          price: 109,
          originalPrice: 139,
          rating: 4.6,
          imageUrl: _img('kids sneakers', 83),
          discount: '-%22',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_kids_dress_cotton',
          category: 'cat_dress',
          price: 99,
          originalPrice: 129,
          rating: 4.6,
          imageUrl: _img('kids dress', 84),
          discount: '-%23',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_kids_set_sport',
          category: 'cat_other',
          price: 119,
          originalPrice: 149,
          rating: 4.7,
          imageUrl: _img('kids tracksuit', 85),
          discount: '-%20',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_kids_jacket_light',
          category: 'cat_other',
          price: 139,
          originalPrice: null,
          rating: 4.4,
          imageUrl: _img('kids jacket', 86),
          discount: null,
          storeName: storeNameKey,
          isOutOfStock: true,
        ),
        Product(
          name: 'prod_kids_cap',
          category: 'cat_accessories',
          price: 25,
          originalPrice: null,
          rating: 4.2,
          imageUrl: _img('kids cap', 87),
          discount: null,
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_kids_backpack',
          category: 'cat_accessories',
          price: 69,
          originalPrice: 89,
          rating: 4.3,
          imageUrl: _img('kids backpack', 88),
          discount: '-%22',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_kids_sweatpants',
          category: 'cat_other',
          price: 59,
          originalPrice: 79,
          rating: 4.6,
          imageUrl: _img('kids sweatpants', 89),
          discount: '-%25',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_kids_pajamas_set',
          category: 'cat_other',
          price: 49,
          originalPrice: 65,
          rating: 4.5,
          imageUrl: _img('kids pajamas', 90),
          discount: '-%25',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_kids_rain_jacket',
          category: 'cat_other',
          price: 99,
          originalPrice: null,
          rating: 4.4,
          imageUrl: _img('kids rain jacket', 91),
          discount: null,
          storeName: storeNameKey,
          isOutOfStock: true,
        ),
        Product(
          name: 'prod_kids_socks_pack',
          category: 'cat_accessories',
          price: 19,
          originalPrice: 25,
          rating: 4.3,
          imageUrl: _img('kids socks', 92),
          discount: '-%24',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_kids_tshirt_print',
          category: 'cat_shirt',
          price: 35,
          originalPrice: 45,
          rating: 4.5,
          imageUrl: _img('kids t shirt', 93),
          discount: '-%22',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_kids_jeans',
          category: 'cat_other',
          price: 69,
          originalPrice: null,
          rating: 4.4,
          imageUrl: _img('kids denim jeans', 94),
          discount: null,
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_kids_sweater',
          category: 'cat_shirt',
          price: 59,
          originalPrice: 79,
          rating: 4.5,
          imageUrl: _img('kids sweater', 95),
          discount: '-%25',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_kids_shoes_sport',
          category: 'cat_shoe',
          price: 119,
          originalPrice: 149,
          rating: 4.6,
          imageUrl: _img('kids sport shoes', 96),
          discount: '-%20',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_kids_hat_winter',
          category: 'cat_accessories',
          price: 25,
          originalPrice: null,
          rating: 4.2,
          imageUrl: _img('kids winter hat', 97),
          discount: null,
          storeName: storeNameKey,
          isOutOfStock: true,
        ),
        Product(
          name: 'prod_kids_dress_party',
          category: 'cat_dress',
          price: 139,
          originalPrice: 169,
          rating: 4.6,
          imageUrl: _img('party dress kids', 98),
          discount: '-%18',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_kids_tracksuit',
          category: 'cat_other',
          price: 129,
          originalPrice: 159,
          rating: 4.6,
          imageUrl: _img('kids tracksuit set', 99),
          discount: '-%19',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_kids_gloves',
          category: 'cat_accessories',
          price: 19,
          originalPrice: 25,
          rating: 4.3,
          imageUrl: _img('kids gloves', 100),
          discount: '-%24',
          storeName: storeNameKey,
        ),
      ];
    }

    // 6. توب فاشن (Mixed - trending)
    if (storeNameKey == 'store_top') {
      return [
        Product(
          name: 'prod_trench_coat',
          category: 'cat_other',
          price: 449,
          originalPrice: 549,
          rating: 4.7,
          imageUrl: _img('trench coat', 101),
          discount: '-%18',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_knit_sweater',
          category: 'cat_shirt',
          price: 189,
          originalPrice: 229,
          rating: 4.6,
          imageUrl: _img('knit sweater', 102),
          discount: '-%17',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_oversized_hoodie',
          category: 'cat_shirt',
          price: 169,
          originalPrice: null,
          rating: 4.5,
          imageUrl: _img('oversized hoodie', 103),
          discount: null,
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_winter_boots_new',
          category: 'cat_shoe',
          price: 299,
          originalPrice: 359,
          rating: 4.6,
          imageUrl: _img('winter boots', 104),
          discount: '-%16',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_wool_beanie',
          category: 'cat_accessories',
          price: 39,
          originalPrice: 49,
          rating: 4.4,
          imageUrl: _img('wool beanie', 105),
          discount: '-%20',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_thermal_gloves_new',
          category: 'cat_accessories',
          price: 45,
          originalPrice: null,
          rating: 4.3,
          imageUrl: _img('thermal gloves', 106),
          discount: null,
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_denim_jeans_wide',
          category: 'cat_other',
          price: 219,
          originalPrice: 269,
          rating: 4.5,
          imageUrl: _img('wide leg jeans', 107),
          discount: '-%19',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_canvas_tote',
          category: 'cat_accessories',
          price: 55,
          originalPrice: null,
          rating: 4.2,
          imageUrl: _img('canvas tote bag', 108),
          discount: null,
          storeName: storeNameKey,
          isOutOfStock: true,
        ),
        Product(
          name: 'prod_windbreaker_jacket',
          category: 'cat_other',
          price: 239,
          originalPrice: 289,
          rating: 4.4,
          imageUrl: _img('windbreaker jacket', 109),
          discount: '-%17',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_long_sleeve_tee',
          category: 'cat_shirt',
          price: 89,
          originalPrice: null,
          rating: 4.3,
          imageUrl: _img('long sleeve t shirt', 110),
          discount: null,
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_straight_jeans',
          category: 'cat_other',
          price: 209,
          originalPrice: 249,
          rating: 4.4,
          imageUrl: _img('straight jeans', 111),
          discount: '-%16',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_chunky_sneakers',
          category: 'cat_shoe',
          price: 319,
          originalPrice: 369,
          rating: 4.6,
          imageUrl: _img('chunky sneakers', 112),
          discount: '-%14',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_black_jeans',
          category: 'cat_other',
          price: 199,
          originalPrice: 239,
          rating: 4.4,
          imageUrl: _img('black jeans', 113),
          discount: '-%17',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_sweatshirt_basic',
          category: 'cat_shirt',
          price: 129,
          originalPrice: 159,
          rating: 4.3,
          imageUrl: _img('basic sweatshirt', 114),
          discount: '-%19',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_oversize_shirt',
          category: 'cat_shirt',
          price: 139,
          originalPrice: null,
          rating: 4.2,
          imageUrl: _img('oversized shirt', 115),
          discount: null,
          storeName: storeNameKey,
          isOutOfStock: true,
        ),
        Product(
          name: 'prod_sneakers_white_chunky2',
          category: 'cat_shoe',
          price: 289,
          originalPrice: 339,
          rating: 4.6,
          imageUrl: _img('white chunky sneakers', 116),
          discount: '-%15',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_joggers',
          category: 'cat_other',
          price: 119,
          originalPrice: null,
          rating: 4.3,
          imageUrl: _img('joggers pants', 117),
          discount: null,
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_beanie_basic2',
          category: 'cat_accessories',
          price: 29,
          originalPrice: 39,
          rating: 4.2,
          imageUrl: _img('beanie', 118),
          discount: '-%26',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_tote_bag_large',
          category: 'cat_accessories',
          price: 69,
          originalPrice: 89,
          rating: 4.2,
          imageUrl: _img('large tote bag', 119),
          discount: '-%22',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_denim_jacket_classic',
          category: 'cat_other',
          price: 299,
          originalPrice: 359,
          rating: 4.5,
          imageUrl: _img('classic denim jacket', 120),
          discount: '-%16',
          storeName: storeNameKey,
        ),
      ];
    }

    return [];
  }

  List<String> _getStoreTags() {
    return ['cat_all', ..._allProducts.map((p) => p.category).toSet()];
  }

  List<Product> get _filteredProducts {
    List<Product> filtered = _allProducts;

    // Search filter (by translated name OR product code key)
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        final translatedName = context.tr(p.name).toLowerCase();
        final codeKey = (p.code ?? p.name).toLowerCase();
        return translatedName.contains(q) || codeKey.contains(q);
      }).toList();
    }

    if (_selectedCategory != 'cat_all') {
      filtered = filtered.where((p) => p.category == _selectedCategory).toList();
    }
    if (_selectedAvailability == 'status_available') {
      filtered = filtered.where((p) => !p.isOutOfStock).toList();
    } else if (_selectedAvailability == 'status_out_of_stock') {
      filtered = filtered.where((p) => p.isOutOfStock).toList();
    }
    filtered = filtered.where((p) => p.price >= _priceRange.start && p.price <= _priceRange.end).toList();
    if (_selectedRating != 'all_ratings') {
      double minRating = 0;
      if (_selectedRating == 'rating_4_5') {
        minRating = 4.5;
      } else if (_selectedRating == 'rating_4_0') {
        minRating = 4.0;
      } else if (_selectedRating == 'rating_3_5') {
        minRating = 3.5;
      }
      filtered = filtered
          .where(
            (p) => _ratingsManager.productRatingOrBase(p.name, p.rating) >= minRating,
          )
          .toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ratingsManager,
      builder: (context, _) => Scaffold(
        backgroundColor: const Color(0xFF0A1931),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStoreHeader(),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1,
                          child: _buildFilterSidebar(),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            // ─── Header Row ───
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  context.tr('products'),
                                  style: GoogleFonts.cairo(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '${_filteredProducts.length} ${context.tr('products')}',
                                  style: GoogleFonts.cairo(fontSize: 13, color: Colors.white54),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // ─── Search Bar ───
                            _buildSearchBar(),
                            const SizedBox(height: 16),

                            // ─── Products Grid or Empty State ───
                            _filteredProducts.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 32),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.05),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.search_off_rounded, color: Colors.white30, size: 40),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          _searchQuery.isNotEmpty
                                            ? context.tr('search_no_result')
                                            : context.tr('no_orders_filter'),
                                          style: GoogleFonts.cairo(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _searchQuery.isNotEmpty
                                            ? context.tr('search_no_result_sub')
                                            : '',
                                          style: GoogleFonts.cairo(fontSize: 12, color: Colors.white38),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),
                                        TextButton.icon(
                                          onPressed: () => setState(() {
                                            _selectedCategory = 'cat_all';
                                            _selectedRating = 'all_ratings';
                                            _selectedAvailability = 'all_availability';
                                            _priceRange = const RangeValues(0, 1500);
                                            _searchQuery = '';
                                            _searchController.clear();
                                          }),
                                          icon: const Icon(Icons.refresh_rounded, color: Colors.blueAccent, size: 16),
                                          label: Text(context.tr('view_all_orders'), style: GoogleFonts.cairo(color: Colors.blueAccent, fontSize: 13)),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    mainAxisExtent: 190,
                                  ),
                                  itemCount: _filteredProducts.length,
                                  itemBuilder: (context, index) {
                                    return _buildProductCard(_filteredProducts[index]);
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoreHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(widget.storeImageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          bottom: -20,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.95),
                  Theme.of(context).colorScheme.secondary.withValues(alpha: 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white.withValues(alpha: 0.22),
                      child: AppBackIconButton(
                        iconSize: 22,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.tr(widget.storeName),
                        style: GoogleFonts.cairo(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (_allProducts.any((p) => p.discount != null && p.discount!.isNotEmpty))
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.pinkAccent.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          context.tr('special_offers'),
                          style: GoogleFonts.cairo(color: Colors.pinkAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.storeRating} • ${widget.storeDistance}${widget.storeDistance == '--' ? '' : context.tr('km_suffix')}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (widget.storeLocation != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openingMap ? null : _openInGoogleMaps,
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: Text(
                        context.tr('open_in_maps'),
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.12),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.white.withOpacity(0.12)),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatWithStoreScreen(storeKey: widget.storeName),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: Text(
                      context.tr('chat_open'),
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.14)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Colors.white54, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        context.tr('store_address'),
                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Text(context.tr('categories_label'), style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                    ..._getStoreTags()
                        .where((tag) => tag != 'cat_all')
                        .map((tag) => _buildTag(tag)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String label) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(context.tr(label), style: const TextStyle(color: Colors.white70, fontSize: 11)),
    );
  }

  Widget _buildFilterSidebar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E5BB3).withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('filter_products'),
            style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 24),
          
          // Category Select
          _buildFilterLabel(context.tr('filter_category')),
          const SizedBox(height: 12),
          _buildModernDropdown(
            value: _selectedCategory,
            itemKeys: _getStoreTags(),
            labelForKey: (k) => context.tr(k),
            onChanged: (val) => setState(() => _selectedCategory = val!),
          ),
          
          const SizedBox(height: 24),
          
          // Price Range
          _buildFilterLabel('${context.tr('price_range')} ${_priceRange.start.toInt()} - ${_priceRange.end.toInt()}${context.tr('currency_suffix')}'),
          const SizedBox(height: 8),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 1500,
            activeColor: Colors.blueAccent,
            inactiveColor: Colors.white10,
            onChanged: (values) => setState(() => _priceRange = values),
          ),
          
          const SizedBox(height: 24),
          
          // Rating Select
          _buildFilterLabel(context.tr('rating')),
          const SizedBox(height: 12),
          _buildModernDropdown(
            value: _selectedRating,
            itemKeys: const ['all_ratings', 'rating_4_5', 'rating_4_0', 'rating_3_5'],
            labelForKey: (k) => context.tr(k),
            onChanged: (val) => setState(() => _selectedRating = val!),
          ),
          const SizedBox(height: 24),
          _buildFilterLabel(context.tr('filter_status')),
          const SizedBox(height: 12),
          _buildModernDropdown(
            value: _selectedAvailability,
            itemKeys: const [
              'all_availability',
              'status_available',
              'status_out_of_stock',
            ],
            labelForKey: (k) => context.tr(k),
            onChanged: (val) => setState(() => _selectedAvailability = val!),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.cairo(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildProductCard(Product p) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(product: p),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E5BB3).withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image and badges
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.network(
                      p.imageUrl,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.blueAccent.withOpacity(0.5),
                            strokeWidth: 2,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.white10,
                          child: const Center(
                            child: Icon(Icons.broken_image_outlined, color: Colors.white24, size: 30),
                          ),
                        );
                      },
                    ),
                  ),
                  if (p.discount != null && p.discount!.isNotEmpty)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(10)),
                        child: Text(p.discount!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  const Positioned(
                    top: 10,
                    left: 10,
                    child: Icon(Icons.favorite_outline, color: Colors.white, size: 20),
                  ),
                  if (p.isOutOfStock)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(8)),
                            child: Text(context.tr('out_of_stock'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr(p.category), style: const TextStyle(color: Colors.white30, fontSize: 10)),
                  const SizedBox(height: 4),
                  Text(context.tr(p.name), style: GoogleFonts.cairo(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _ratingsManager
                            .productRatingOrBase(p.name, p.rating)
                            .toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.code ?? _buildProductCode(p.name),
                    style: const TextStyle(color: Colors.white30, fontSize: 10),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('${p.price}${context.tr('currency_suffix')}', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 8),
                      if (p.originalPrice != null)
                        Text('${p.originalPrice}${context.tr('currency_suffix')}', style: const TextStyle(color: Colors.white24, fontSize: 11, decoration: TextDecoration.lineThrough)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _searchQuery.isNotEmpty
              ? Colors.blueAccent.withOpacity(0.6)
              : Colors.white.withOpacity(0.1),
          width: 1.2,
        ),
        boxShadow: [
          if (_searchQuery.isNotEmpty)
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 1,
            ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
        textDirection: TextDirection.rtl,
        onChanged: (val) => setState(() => _searchQuery = val.trim()),
        decoration: InputDecoration(
          hintText: context.tr('search_product'),
          hintStyle: GoogleFonts.cairo(color: Colors.white38, fontSize: 13),
          prefixIcon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _searchQuery.isNotEmpty
                ? IconButton(
                    key: const ValueKey('clear'),
                    icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
                    onPressed: () => setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                    }),
                  )
                : const Icon(
                    key: ValueKey('search'),
                    Icons.search_rounded,
                    color: Colors.white38,
                    size: 20,
                  ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildModernDropdown({
    required String value,
    required List<String> itemKeys,
    required String Function(String key) labelForKey,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF111E36),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 18),
          isExpanded: true,
          style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
          items: itemKeys
              .map((key) => DropdownMenuItem(
                    value: key,
                    child: Text(labelForKey(key)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

}
