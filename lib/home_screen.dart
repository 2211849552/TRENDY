import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1931), // Matching Dark Blue Background
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 10),
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 20),
                  // Welcome Banner
                  _buildWelcomeBanner(),
                  const SizedBox(height: 24),
                  // Search and Filter
                  _buildSearchSection(),
                  const SizedBox(height: 32),
                  // Stores Section Title
                  const Text(
                    'المتاجر المتوفرة (5)',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
            // Stores Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: _buildStoreGrid(),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E5BB3).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Trendy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.checkroom_rounded, color: Colors.blueAccent, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E5BB3), // Blue card
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildBannerIcon(Icons.chat_bubble_outline),
                  const SizedBox(width: 12),
                  _buildBannerIcon(Icons.notifications_none),
                ],
              ),
              const SizedBox(), // Spacer
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'مرحباً بك في متجري',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'اكتشف أفضل المتاجر والمنتجات في ليبيا',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'أهلاً hajer',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      children: [
        // Search Bar
        TextField(
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: '...ابحث عن متجر',
            hintStyle: const TextStyle(color: Colors.white30),
            prefixIcon: const Icon(Icons.search, color: Colors.white30),
            filled: true,
            fillColor: const Color(0xFF1E5BB3).withValues(alpha: 0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Filter Dropdowns
        Row(
          children: [
            Expanded(child: _buildDropdown('الأقرب')),
            const SizedBox(width: 12),
            Expanded(child: _buildDropdown('جميع المتاجر')),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E5BB3).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
          Text(title, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

    Widget _buildStoreGrid() {
    final List<Map<String, dynamic>> stores = [
      {
        'name': 'متجر الأناقة',
        'category': 'فساتين',
        'rating': 4.8,
        'distance': '2.5 كم',
        'imageUrl': 'https://images.unsplash.com/photo-1539106604284-9697c1873a11?auto=format&fit=crop&q=80&w=800',
        'discount': 'تخفيضات حتى 40%',
      },
      {
        'name': 'بوتيك الموضة',
        'category': 'ملابس رجالية',
        'rating': 4.5,
        'distance': '1.2 كم',
        'imageUrl': 'https://images.unsplash.com/photo-1490114538077-0a7f8cb49891?auto=format&fit=crop&q=80&w=800',
        'discount': null,
      },
      {
        'name': 'الرجل الأنيق',
        'category': 'بدل رجالية',
        'rating': 4.6,
        'distance': '0.8 كم',
        'imageUrl': 'https://images.unsplash.com/photo-1593032465175-481ac7f401a0?auto=format&fit=crop&q=80&w=800',
        'discount': 'تخفيضات حتى 30%',
      },
      {
        'name': 'متجر الفخامة',
        'category': 'فساتين سهرة',
        'rating': 4.7,
        'distance': '5 كم',
        'imageUrl': 'https://images.unsplash.com/photo-1566174053879-31528523f8ae?auto=format&fit=crop&q=80&w=800',
        'discount': null,
      },
      {
        'name': 'عالم الأطفال',
        'category': 'ملابس أطفال',
        'rating': 4.9,
        'distance': '3.8 كم',
        'imageUrl': 'https://images.unsplash.com/photo-1622290291468-a28f7a7ae6a8?auto=format&fit=crop&q=80&w=800',
        'discount': 'تخفيضات حتى 25%',
      },
      {
        'name': 'توب فاشن',
        'category': 'ملابس شتوية',
        'rating': 4.9,
        'distance': '2.1 كم',
        'imageUrl': 'https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&q=80&w=800',
        'discount': null,
      },
    ];

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        mainAxisExtent: 260,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final store = stores[index];
          return _buildStoreCard(
            name: store['name'],
            category: store['category'],
            rating: store['rating'],
            distance: store['distance'],
            imageUrl: store['imageUrl'],
            discount: store['discount'],
          );
        },
        childCount: stores.length,
      ),
    );
  }

  Widget _buildStoreCard({
    required String name,
    required String category,
    required double rating,
    required String distance,
    required String imageUrl,
    String? discount,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E5BB3).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Store Image with badges
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    imageUrl,
                    height: double.infinity,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.blueAccent,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.white10,
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined, color: Colors.white24, size: 40),
                        ),
                      );
                    },
                  ),
                ),
                // Discount Badge (matching current mockup)
                if (discount != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D1FF).withValues(alpha: 0.8), // Cyan/Light Blue
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        discount,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Store Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  category,
                  style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(rating.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(width: 4),
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  distance,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
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
