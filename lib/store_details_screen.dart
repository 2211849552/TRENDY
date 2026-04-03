import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Product {
  final String name;
  final String category;
  final double price;
  final double originalPrice;
  final double rating;
  final String imageUrl;
  final String discount;

  Product({
    required this.name,
    required this.category,
    required this.price,
    required this.originalPrice,
    required this.rating,
    required this.imageUrl,
    required this.discount,
  });
}

class StoreDetailsScreen extends StatefulWidget {
  final String storeName;
  final String storeCategory;
  final double storeRating;
  final String storeDistance;
  final String storeImageUrl;

  const StoreDetailsScreen({
    super.key,
    required this.storeName,
    required this.storeCategory,
    required this.storeRating,
    required this.storeDistance,
    required this.storeImageUrl,
  });

  @override
  State<StoreDetailsScreen> createState() => _StoreDetailsScreenState();
}

class _StoreDetailsScreenState extends State<StoreDetailsScreen> {
  String _selectedCategory = 'الكل';
  RangeValues _priceRange = const RangeValues(0, 1500);
  String _selectedRating = 'جميع التقييمات';
  int _bottomNavIndex = 0;
  late final List<Product> _allProducts;

  @override
  void initState() {
    super.initState();
    _allProducts = _getMockProducts(widget.storeCategory, widget.storeName);
  }

  List<Product> _getMockProducts(String storeCat, String storeName) {
    // 1. متجر الأناقة (Casual/Mainstream Women)
    if (storeName.contains('الأناقة')) {
      return [
        Product(
          name: 'فستان صيفي مشجر',
          category: 'فستان',
          price: 180,
          originalPrice: 250,
          rating: 4.8,
          imageUrl: 'https://images.unsplash.com/photo-1585116462102-bb34469ca436?auto=format&fit=crop&q=80&w=400',
          discount: '-%28',
        ),
        Product(
          name: 'بلوزة قطنية أنيقة',
          category: 'قميص',
          price: 95,
          originalPrice: 130,
          rating: 4.6,
          imageUrl: 'https://images.unsplash.com/photo-1485960994840-00aa453e0f2d?auto=format&fit=crop&q=80&w=400',
          discount: '-%25',
        ),
        Product(
          name: 'حقيبة كتف يومية',
          category: 'إكسسوارات',
          price: 140,
          originalPrice: 200,
          rating: 4.7,
          imageUrl: 'https://images.unsplash.com/photo-1591561954557-26941169b49e?auto=format&fit=crop&q=80&w=400',
          discount: '-%30',
        ),
        Product(
          name: 'تنورة جينز عصرية',
          category: 'أخرى',
          price: 115,
          originalPrice: 160,
          rating: 4.5,
          imageUrl: 'https://images.unsplash.com/photo-1541333323-24842353b221?auto=format&fit=crop&q=80&w=400',
          discount: '-%28',
        ),
        Product(
          name: 'صندل صيفي مريح',
          category: 'حذاء',
          price: 130,
          originalPrice: 190,
          rating: 4.4,
          imageUrl: 'https://images.unsplash.com/photo-1560343770-ebe30209e41d?auto=format&fit=crop&q=80&w=400',
          discount: '-%31',
        ),
        Product(
          name: 'وشاح وردي ناعم',
          category: 'إكسسوارات',
          price: 45,
          originalPrice: 70,
          rating: 4.8,
          imageUrl: 'https://images.unsplash.com/photo-1494913148679-221656f70b27?auto=format&fit=crop&q=80&w=400',
          discount: '-%35',
        ),
      ];
    }
    // 2. متجر الفخامة (High-end Evening Wear)
    if (storeName.contains('الفخامة')) {
      return [
        Product(
          name: 'فستان سهرة ملكي',
          category: 'فستان',
          price: 850,
          originalPrice: 1200,
          rating: 4.9,
          imageUrl: 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?auto=format&fit=crop&q=80&w=400',
          discount: '-%30',
        ),
        Product(
          name: 'طقم مجوهرات فاخر',
          category: 'إكسسوارات',
          price: 550,
          originalPrice: 800,
          rating: 5.0,
          imageUrl: 'https://images.unsplash.com/photo-1515377905703-c4788e51af15?auto=format&fit=crop&q=80&w=400',
          discount: '-%30',
        ),
        Product(
          name: 'حذاء مخملي للسهرة',
          category: 'حذاء',
          price: 320,
          originalPrice: 450,
          rating: 4.8,
          imageUrl: 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?auto=format&fit=crop&q=80&w=400',
          discount: '-%30',
        ),
        Product(
          name: 'حقيبة يد مرصعة',
          category: 'إكسسوارات',
          price: 420,
          originalPrice: 600,
          rating: 4.9,
          imageUrl: 'https://images.unsplash.com/photo-1585145029026-c2770d188688?auto=format&fit=crop&q=80&w=400',
          discount: '-%30',
        ),
        Product(
          name: 'وشاح حريري فاخر',
          category: 'إكسسوارات',
          price: 180,
          originalPrice: 260,
          rating: 4.7,
          imageUrl: 'https://images.unsplash.com/photo-1584917865442-de89df147d5e?auto=format&fit=crop&q=80&w=400',
          discount: '-%30',
        ),
        Product(
          name: 'كيب سهرة أنيق',
          category: 'أخرى',
          price: 350,
          originalPrice: 500,
          rating: 4.8,
          imageUrl: 'https://images.unsplash.com/photo-1566174053879-31528523f8ae?auto=format&fit=crop&q=80&w=400',
          discount: '-%30',
        ),
      ];
    }
    // 3. الرجل الأنيق (Formal Men)
    if (storeName.contains('الرجل الأنيق')) {
      return [
        Product(
          name: 'بدلة توسيدو سوداء',
          category: 'بدلة',
          price: 550,
          originalPrice: 750,
          rating: 4.9,
          imageUrl: 'https://images.unsplash.com/photo-1594932224520-2f9caaf8ca8c?auto=format&fit=crop&q=80&w=400',
          discount: '-%25',
        ),
        Product(
          name: 'قميص أكسفورد أبيض',
          category: 'قميص',
          price: 180,
          originalPrice: 250,
          rating: 4.8,
          imageUrl: 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?auto=format&fit=crop&q=80&w=400',
          discount: '-%28',
        ),
        Product(
          name: 'حذاء أوكسفورد جلدي',
          category: 'حذاء',
          price: 280,
          originalPrice: 400,
          rating: 4.8,
          imageUrl: 'https://images.unsplash.com/photo-1614252235316-8c857d38b5f4?auto=format&fit=crop&q=80&w=400',
          discount: '-%30',
        ),
        Product(
          name: 'رابطة عنق حريرية',
          category: 'إكسسوارات',
          price: 75,
          originalPrice: 110,
          rating: 4.7,
          imageUrl: 'https://images.unsplash.com/photo-1589756818134-d07949511b2f?auto=format&fit=crop&q=60&w=300',
          discount: '-%31',
        ),
        Product(
          name: 'ساعة يد كلاسيكية',
          category: 'إكسسوارات',
          price: 450,
          originalPrice: 650,
          rating: 4.9,
          imageUrl: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&q=60&w=300',
          discount: '-%30',
        ),
        Product(
          name: 'حزام جلد طبيعي',
          category: 'إكسسوارات',
          price: 95,
          originalPrice: 140,
          rating: 3.5,
          imageUrl: 'https://images.unsplash.com/photo-1614165939016-566b69ce5d77?auto=format&fit=crop&q=60&w=300',
          discount: '-%32',
        ),
      ];
    }
    // 4. بوتيك الموضة (Casual/Streetwear Men)
    if (storeName.contains('الموضة')) {
      return [
        Product(
          name: 'جاكيت جينز عصري',
          category: 'جاكيت',
          price: 220,
          originalPrice: 300,
          rating: 4.7,
          imageUrl: 'https://images.unsplash.com/photo-1551537482-f2075a1d41f2?auto=format&fit=crop&q=80&w=400',
          discount: '-%25',
        ),
        Product(
          name: 'تيشيرت مطبوع',
          category: 'قميص',
          price: 85,
          originalPrice: 120,
          rating: 4.6,
          imageUrl: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&q=80&w=400',
          discount: '-%30',
        ),
        Product(
          name: 'حذاء سنيكرز أنيق',
          category: 'حذاء',
          price: 195,
          originalPrice: 280,
          rating: 4.8,
          imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&q=80&w=400',
          discount: '-%30',
        ),
        Product(
          name: 'هودي قطني مريح',
          category: 'قميص',
          price: 145,
          originalPrice: 210,
          rating: 4.7,
          imageUrl: 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?auto=format&fit=crop&q=80&w=400',
          discount: '-%31',
        ),
        Product(
          name: 'قبعة بيسبول عصرية',
          category: 'إكسسوارات',
          price: 55,
          originalPrice: 80,
          rating: 4.5,
          imageUrl: 'https://images.unsplash.com/photo-1521369909029-2afed882baee?auto=format&fit=crop&q=60&w=300',
          discount: '-%31',
        ),
        Product(
          name: 'شورت كاجوال مريح',
          category: 'بنطال',
          price: 110,
          originalPrice: 160,
          rating: 4.6,
          imageUrl: 'https://images.unsplash.com/photo-1591195853828-11db59a44f6b?auto=format&fit=crop&q=80&w=400',
          discount: '-%31',
        ),
      ];
    }
    // 5. عالم الأطفال
    if (storeCat.contains('أطفال')) {
      return [
        Product(
          name: 'طقم رياضي للأطفال',
          category: 'أخرى',
          price: 110,
          originalPrice: 160,
          rating: 4.9,
          imageUrl: 'https://images.unsplash.com/photo-1519457431373-ca7a72bb9c9a?auto=format&fit=crop&q=80&w=400',
          discount: '-%30',
        ),
        Product(
          name: 'فستان بناتي وردي',
          category: 'فستان',
          price: 95,
          originalPrice: 140,
          rating: 4.8,
          imageUrl: 'https://images.unsplash.com/photo-1518831959646-742c3a14ebf7?auto=format&fit=crop&q=80&w=400',
          discount: '-%32',
        ),
        Product(
          name: 'حقيبة ظهر مدرسية',
          category: 'إكسسوارات',
          price: 75,
          originalPrice: 110,
          rating: 4.7,
          imageUrl: 'https://images.unsplash.com/photo-1587585520892-0b2f51f156d6?auto=format&fit=crop&q=80&w=400',
          discount: '-%30',
        ),
        Product(
          name: 'بيجامة نوم مريحة',
          category: 'أخرى',
          price: 65,
          originalPrice: 100,
          rating: 4.8,
          imageUrl: 'https://images.unsplash.com/photo-1523381210434-271e8be1f52b?auto=format&fit=crop&q=80&w=400',
          discount: '-%35',
        ),
        Product(
          name: 'حذاء رياضي ملون',
          category: 'حذاء',
          price: 125,
          originalPrice: 180,
          rating: 4.7,
          imageUrl: 'https://images.unsplash.com/photo-1514989940723-e8e51635b782?auto=format&fit=crop&q=80&w=400',
          discount: '-%30',
        ),
        Product(
          name: 'لعبة دب قطني',
          category: 'أخرى',
          price: 45,
          originalPrice: 70,
          rating: 4.9,
          imageUrl: 'https://images.unsplash.com/photo-1559410123921-21ca2b065f1f?auto=format&fit=crop&q=80&w=400',
          discount: '-%35',
        ),
      ];
    }
    // 6. توب فاشن (Winter Items)
    if (storeCat.contains('شتوية')) {
      return [
        Product(
          name: 'معطف صوف شتوي',
          category: 'جاكيت',
          price: 380,
          originalPrice: 550,
          rating: 4.9,
          imageUrl: 'https://images.unsplash.com/photo-1544022613-e87ca75a784a?auto=format&fit=crop&q=60&w=300',
          discount: '-%30',
        ),
        Product(
          name: 'كنزة صوفية سميكة',
          category: 'قميص',
          price: 155,
          originalPrice: 220,
          rating: 4.8,
          imageUrl: 'https://images.unsplash.com/photo-1520638029751-09017ae247f9?auto=format&fit=crop&q=60&w=300',
          discount: '-%30',
        ),
        Product(
          name: 'بلوفر هاي كول',
          category: 'قميص',
          price: 130,
          originalPrice: 190,
          rating: 4.8,
          imageUrl: 'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?auto=format&fit=crop&q=60&w=300',
          discount: '-%30',
        ),
        Product(
          name: 'بوت شتوي ووتربرووف',
          category: 'حذاء',
          price: 245,
          originalPrice: 350,
          rating: 4.8,
          imageUrl: 'https://images.unsplash.com/photo-1608256246200-53e635b5b65f?auto=format&fit=crop&q=60&w=300',
          discount: '-%30',
        ),
        Product(
          name: 'وشاح صوفي دافئ',
          category: 'إكسسوارات',
          price: 75,
          originalPrice: 110,
          rating: 4.7,
          imageUrl: 'https://images.unsplash.com/photo-1520903074185-8eca362b3dce?auto=format&fit=crop&q=60&w=300',
          discount: '-%32',
        ),
        Product(
          name: 'جاكيت مبطن فاخر',
          category: 'جاكيت',
          price: 420,
          originalPrice: 600,
          rating: 4.9,
          imageUrl: 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?auto=format&fit=crop&q=60&w=300',
          discount: '-%30',
        ),
      ];
    }
    // Fallback default
    return [
      Product(
        name: 'منتج عصري',
        category: 'أخرى',
        price: 100,
        originalPrice: 150,
        rating: 4.5,
        imageUrl: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&q=80&w=400',
        discount: '-%33',
      ),
    ];
  }

  List<String> _getStoreTags() {
    // Dynamically get unique categories from the store's products
    return _allProducts.map((p) => p.category).toSet().toList();
  }

  List<Product> get _filteredProducts {
    return _allProducts.where((p) {
      bool catMatch = _selectedCategory == 'الكل' || p.category == _selectedCategory;
      bool priceMatch = p.price >= _priceRange.start && p.price <= _priceRange.end;
      
      double minRating = 0;
      if (_selectedRating == '4.5+ نجوم') minRating = 4.5;
      else if (_selectedRating == '4.0+ نجوم') minRating = 4.0;
      else if (_selectedRating == '3.5+ نجوم') minRating = 3.5;
      bool ratingMatch = p.rating >= minRating;

      return catMatch && priceMatch && ratingMatch;
    }).toList();
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
                // Store Header Banner
                _buildStoreHeader(),
                
                const SizedBox(height: 32),
                
                // Main Content (Products and Filters)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Right Side: Filtering (Desktop-like layout as shown in screenshot)
                      Expanded(
                        flex: 1,
                        child: _buildFilterSidebar(),
                      ),
                      
                      const SizedBox(width: 24),

                      // Left Side: Product List
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'المنتجات (${_filteredProducts.length})',
                              style: GoogleFonts.cairo(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Products Grid
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                mainAxisExtent: 280,
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
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildStoreHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Banner Image
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
        // Back Button
        Positioned(
          top: 16,
          left: 16,
          child: CircleAvatar(
            backgroundColor: Colors.black38,
            child: IconButton(
              icon: const Icon(Icons.arrow_forward, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        // Store Info Overlay Card (matching the style in screenshots)
        Positioned(
          bottom: -20,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E5BB3).withValues(alpha: 0.95),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent.withValues(alpha: 0.3),
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
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    );
  }

  Widget _buildFilterSidebar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E5BB3).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تصفية المنتجات',
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
            onChanged: (val) => setState(() => _selectedRating = val!),
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E5BB3).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image and badges
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    p.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.blueAccent.withValues(alpha: 0.5),
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
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(10)),
                    child: Text(p.discount, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Icon(Icons.favorite_outline, color: Colors.white, size: 20),
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
                    Text('${p.originalPrice} د.ل', style: const TextStyle(color: Colors.white24, fontSize: 11, decoration: TextDecoration.lineThrough)),
                  ],
                ),
              ],
            ),
          ),
        ],
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
        color: Colors.white.withValues(alpha: 0.05),
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

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _bottomNavIndex,
      onTap: (index) {
        setState(() => _bottomNavIndex = index);
        if (index == 0) Navigator.pop(context); // Feedback: go home
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF0A1931),
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.white54,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'الرئيسية'),
        BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), activeIcon: Icon(Icons.storefront), label: 'المتجر'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite_outline), activeIcon: Icon(Icons.favorite), label: 'المفضلة'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_basket_outlined), activeIcon: Icon(Icons.shopping_basket), label: 'السلة'),
        BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'الإعدادات'),
      ],
    );
  }
}
