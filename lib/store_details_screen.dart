import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'l10n/app_strings.dart';
import 'locale/app_locale.dart';
import 'models/product.dart';
import 'product_details_screen.dart';

class StoreDetailsScreen extends StatefulWidget {
  final String storeName;
  final String storeCategory;
  final double storeRating;
  final String storeDistance;
  final String storeImageUrl;
  final String? storeDiscount;

  const StoreDetailsScreen({
    super.key,
    required this.storeName,
    required this.storeCategory,
    required this.storeRating,
    required this.storeDistance,
    required this.storeImageUrl,
    this.storeDiscount,
  });

  @override
  State<StoreDetailsScreen> createState() => _StoreDetailsScreenState();
}

class _StoreDetailsScreenState extends State<StoreDetailsScreen> {
  String _selectedCategory = 'cat_all';
  RangeValues _priceRange = const RangeValues(0, 1500);
  String _selectedRating = 'all_ratings';
  late final List<Product> _allProducts;

  @override
  void initState() {
    super.initState();
    _allProducts = _getMockProducts(widget.storeCategory, widget.storeName, widget.storeDiscount != null);
  }

  List<Product> _getMockProducts(String storeCat, String storeNameKey, bool hasStoreDiscount) {
    List<Product> products = _generateRawProducts(storeCat, storeNameKey);
    
    if (!hasStoreDiscount) {
      return products.map((p) => Product(
        name: p.name,
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
    return products;
  }

  List<Product> _generateRawProducts(String storeCat, String storeNameKey) {
    // 1. متجر الأناقة (Casual/Mainstream Women)
    if (storeNameKey == 'store_elegance') {
      return [
        Product(
          name: 'prod_summer_dress',
          category: 'cat_dress',
          price: 180,
          originalPrice: 250,
          rating: 4.8,
          imageUrl: 'https://images.unsplash.com/photo-1585116462102-bb34469ca436?auto=format&fit=crop&q=80&w=400',
          discount: '-%28',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_cotton_blouse',
          category: 'cat_shirt',
          price: 95,
          originalPrice: null,
          rating: 4.6,
          imageUrl: 'https://images.unsplash.com/photo-1485960994840-00aa453e0f2d?auto=format&fit=crop&q=80&w=400',
          discount: null,
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_shoulder_bag',
          category: 'cat_accessories',
          price: 140,
          originalPrice: 200,
          rating: 4.7,
          imageUrl: 'https://images.unsplash.com/photo-1591561954557-26941169b49e?auto=format&fit=crop&q=80&w=400',
          discount: '-%30',
          storeName: storeNameKey,
          isOutOfStock: true,
        ),
        Product(
          name: 'prod_denim_skirt',
          category: 'cat_other',
          price: 115,
          originalPrice: 160,
          rating: 3.5,
          imageUrl: 'https://images.unsplash.com/photo-1541333323-24842353b221?auto=format&fit=crop&q=80&w=400',
          discount: '-%28',
          storeName: storeNameKey,
          isOutOfStock: true,
        ),
        Product(
          name: 'prod_summer_sandal',
          category: 'cat_shoe',
          price: 130,
          originalPrice: 190,
          rating: 4.0,
          imageUrl: 'https://images.unsplash.com/photo-1560343770-ebe30209e41d?auto=format&fit=crop&q=80&w=400',
          discount: '-%31',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_pink_scarf',
          category: 'cat_accessories',
          price: 45,
          originalPrice: 70,
          rating: 4.8,
          imageUrl: 'https://images.unsplash.com/photo-1494913148679-221656f70b27?auto=format&fit=crop&q=80&w=400',
          discount: '-%35',
          storeName: storeNameKey,
        ),
      ];
    }
    // 2. متجر الفخامة (High-end Evening Wear)
    if (storeNameKey == 'store_luxury') {
      return [
        Product(
          name: 'prod_royal_dress',
          category: 'cat_dress',
          price: 850,
          originalPrice: 1200,
          rating: 4.0,
          imageUrl: 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?auto=format&fit=crop&q=80&w=400',
          discount: '-%30',
          storeName: storeNameKey,
          isOutOfStock: true,
        ),
        Product(
          name: 'prod_luxury_jewelry',
          category: 'cat_accessories',
          price: 550,
          originalPrice: 800,
          rating: 5.0,
          imageUrl: 'https://images.unsplash.com/photo-1515377905703-c4788e51af15?auto=format&fit=crop&q=80&w=400',
          discount: '-%30',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_velvet_clutch',
          category: 'cat_accessories',
          price: 320,
          originalPrice: 450,
          rating: 3.5,
          imageUrl: 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?auto=format&fit=crop&q=80&w=400',
          discount: '-%30',
          storeName: storeNameKey,
          isOutOfStock: true,
        ),
        Product(
          name: 'prod_gold_heels',
          category: 'cat_shoe',
          price: 420,
          originalPrice: 600,
          rating: 4.9,
          imageUrl: 'https://images.unsplash.com/photo-1585145029026-c2770d188688?auto=format&fit=crop&q=80&w=400',
          discount: '-%30',
          storeName: storeNameKey,
        ),
      ];
    }
    // 3. الرجل الأنيق (Formal Men)
    if (storeNameKey == 'store_gentle') {
      return [
        Product(
          name: 'prod_formal_suit',
          category: 'cat_other',
          price: 550,
          originalPrice: 750,
          rating: 4.0,
          imageUrl: 'https://images.unsplash.com/photo-1594932224520-2f9caaf8ca8c?auto=format&fit=crop&q=80&w=400',
          discount: '-%25',
          storeName: storeNameKey,
          isOutOfStock: true,
        ),
        Product(
          name: 'prod_silk_tie',
          category: 'cat_accessories',
          price: 180,
          originalPrice: 250,
          rating: 4.8,
          imageUrl: 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?auto=format&fit=crop&q=80&w=400',
          discount: '-%28',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_classic_shoe',
          category: 'cat_shoe',
          price: 280,
          originalPrice: 400,
          rating: 4.8,
          imageUrl: 'https://images.unsplash.com/photo-1614252235316-8c857d38b5f4?auto=format&fit=crop&q=80&w=400',
          discount: '-%30',
          storeName: storeNameKey,
        ),
      ];
    }
    // 4. بوتيك الموضة (Casual/Streetwear Men)
    if (storeNameKey == 'store_fashion') {
      return [
        Product(
          name: 'prod_casual_shirt',
          category: 'cat_shirt',
          price: 220,
          originalPrice: 300,
          rating: 4.7,
          imageUrl: 'https://images.unsplash.com/photo-1551537482-f2075a1d41f2?auto=format&fit=crop&q=80&w=400',
          discount: '-%25',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_sport_sneakers',
          category: 'cat_shoe',
          price: 195,
          originalPrice: 280,
          rating: 4.8,
          imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&q=80&w=400',
          discount: '-%30',
          storeName: storeNameKey,
        ),
      ];
    }
    // 5. عالم الأطفال
    if (storeNameKey == 'store_kids') {
      return [
        Product(
          name: 'prod_baby_set',
          category: 'cat_other',
          price: 110,
          originalPrice: 160,
          rating: 4.9,
          imageUrl: 'https://images.unsplash.com/photo-1519457431373-ca7a72bb9c9a?auto=format&fit=crop&q=80&w=400',
          discount: '-%30',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_girl_dress',
          category: 'cat_dress',
          price: 95,
          originalPrice: 140,
          rating: 4.8,
          imageUrl: 'https://images.unsplash.com/photo-1518831959646-742c3a14ebf7?auto=format&fit=crop&q=80&w=400',
          discount: '-%32',
          storeName: storeNameKey,
        ),
      ];
    }
    // 6. توب فاشن
    if (storeNameKey == 'store_top') {
      return [
        Product(
          name: 'prod_winter_boots',
          category: 'cat_shoe',
          price: 245,
          originalPrice: 350,
          rating: 4.8,
          imageUrl: 'https://images.unsplash.com/photo-1608256246200-53e635b5b65f?auto=format&fit=crop&q=60&w=300',
          discount: '-%30',
          storeName: storeNameKey,
        ),
        Product(
          name: 'prod_long_coat',
          category: 'cat_other',
          price: 420,
          originalPrice: 600,
          rating: 4.9,
          imageUrl: 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?auto=format&fit=crop&q=60&w=300',
          discount: '-%30',
          storeName: storeNameKey,
        ),
      ];
    }
    return [];
  }

  List<String> _getStoreTags() {
    return ['cat_all', ..._allProducts.map((p) => p.category).toSet().toList()];
  }

  List<Product> get _filteredProducts {
    List<Product> filtered = _allProducts;
    if (_selectedCategory != 'cat_all') {
      filtered = filtered.where((p) => p.category == _selectedCategory).toList();
    }
    filtered = filtered.where((p) => p.price >= _priceRange.start && p.price <= _priceRange.end).toList();
    if (_selectedRating != 'all_ratings') {
      double minRating = 0;
      if (_selectedRating == 'rating_4_5') minRating = 4.5;
      else if (_selectedRating == 'rating_4_0') minRating = 4.0;
      else if (_selectedRating == 'rating_3_5') minRating = 3.5;
      filtered = filtered.where((p) => p.rating >= minRating).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                            Text(
                              context.tr('products'),
                              style: GoogleFonts.cairo(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text('${_filteredProducts.length} ${context.tr('products')}', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white54)),
                            const SizedBox(height: 16),
                            _filteredProducts.isEmpty 
                              ? Center(
                                  child: Column(
                                    children: [
                                      Text(context.tr('no_orders_filter'), style: GoogleFonts.cairo(fontSize: 18, color: Colors.white70)),
                                      const SizedBox(height: 12),
                                      TextButton(
                                        onPressed: () => setState(() {
                                          _selectedCategory = 'cat_all';
                                          _selectedRating = 'all_ratings';
                                          _priceRange = const RangeValues(0, 1500);
                                        }),
                                        child: Text(context.tr('view_all_orders'), style: GoogleFonts.cairo(color: Colors.blueAccent)),
                                      ),
                                    ],
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
          top: 16,
          right: 16,
          child: CircleAvatar(
            backgroundColor: Colors.black38,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
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
              color: const Color(0xFF1E5BB3).withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.storeName,
                      style: GoogleFonts.cairo(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
                          'عروض خاصة',
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
                      '${widget.storeRating} • ${widget.storeDistance}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Colors.white54, size: 16),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'طرابلس، شارع الجمهورية',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Tags
                Row(
                  children: [
                    const Text('التصنيفات:', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(width: 10),
                    ..._getStoreTags().map((tag) => _buildTag(tag)),
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
      child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
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
          _buildFilterLabel('تصنيف حسب الفئة'),
          const SizedBox(height: 12),
          _buildModernDropdown(
            value: _selectedCategory,
            items: ['الكل', ..._getStoreTags()],
            onChanged: (val) => setState(() => _selectedCategory = val!),
          ),
          
          const SizedBox(height: 24),
          
          // Price Range
          _buildFilterLabel('نطاق السعر: ${_priceRange.start.toInt()} - ${_priceRange.end.toInt()} د.ل'),
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
          _buildFilterLabel('التقييم'),
          const SizedBox(height: 12),
          _buildModernDropdown(
            value: _selectedRating,
            items: ['جميع التقييمات', '4.5+ نجوم', '4.0+ نجوم', '3.5+ نجوم'],
            onChanged: (val) => setState(() => _selectedRating = val == context.tr('rating_4_5') ? 'rating_4_5' : val == context.tr('rating_4_0') ? 'rating_4_0' : val == context.tr('rating_3_5') ? 'rating_3_5' : 'all_ratings'),
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
                      fit: BoxFit.cover,
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
                            child: const Text('نفدت الكمية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
                  Text(p.category, style: const TextStyle(color: Colors.white30, fontSize: 10)),
                  const SizedBox(height: 4),
                  Text(p.name, style: GoogleFonts.cairo(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text('${p.rating}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('${p.price} د.ل', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 8),
                      if (p.originalPrice != null)
                        Text('${p.originalPrice} د.ل', style: const TextStyle(color: Colors.white24, fontSize: 11, decoration: TextDecoration.lineThrough)),
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

  Widget _buildModernDropdown({
    required String value,
    required List<String> items,
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
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

}
