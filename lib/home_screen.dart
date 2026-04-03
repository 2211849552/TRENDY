import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'complaints_screen.dart';
import 'notifications_screen.dart';
import 'store_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _searchQuery = "";
  String _selectedCategory = "جميع المتاجر";
  String _selectedSort = "الأقرب";

  final List<Map<String, dynamic>> _stores = [
    {
      'name': 'متجر الأناقة',
      'category': 'فساتين',
      'rating': 4.8,
      'distance': '2.5 كم',
      'imageUrl': 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&q=80&w=800',
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
      'imageUrl': 'https://images.unsplash.com/photo-1621451537084-482c73073a0f?auto=format&fit=crop&q=80&w=800',
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

  List<Map<String, dynamic>> get _filteredStores {
    List<Map<String, dynamic>> filtered = _stores.where((store) {
      final nameMatches = store['name'].toLowerCase().contains(_searchQuery.toLowerCase());
      
      bool categoryMatches = _selectedCategory == "جميع المتاجر";
      if (_selectedCategory == "رجالي") {
        categoryMatches = store['category'].toString().contains("رجالية") || store['category'].toString().contains("رجالي");
      } else if (_selectedCategory == "نسائي") {
        categoryMatches = store['category'].toString().contains("فساتين") || store['category'].toString().contains("نسائي");
      } else if (_selectedCategory == "أطفال") {
        categoryMatches = store['category'].toString().contains("أطفال");
      }
      
      return nameMatches && categoryMatches;
    }).toList();

    // Apply Sorting
    if (_selectedSort == "الأعلى تقييماً") {
      filtered.sort((a, b) => b['rating'].compareTo(a['rating']));
    } else if (_selectedSort == "العروض أولاً") {
      filtered.sort((a, b) {
        if (a['discount'] != null && b['discount'] == null) return -1;
        if (a['discount'] == null && b['discount'] != null) return 1;
        return 0;
      });
    } else if (_selectedSort == "الأقرب") {
      filtered.sort((a, b) {
        double distA = double.tryParse(a['distance'].split(' ')[0]) ?? 99.0;
        double distB = double.tryParse(b['distance'].split(' ')[0]) ?? 99.0;
        return distA.compareTo(distB);
      });
    }

    return filtered;
  }

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
                  Text(
                    'المتاجر المتوفرة (${_filteredStores.length})',
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Right side: All the Text (First child in RTL becomes Right)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
          ),
          // Left side: Icons (Second child in RTL becomes Left)
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ComplaintsScreen()),
                  );
                },
                child: _buildBannerIcon(Icons.chat_bubble_outline),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                  );
                },
                child: _buildBannerIcon(Icons.notifications_none),
              ),
            ],
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
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: '...ابحث عن متجر',
            hintStyle: GoogleFonts.cairo(color: Colors.white30, fontSize: 13),
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
            Expanded(
              child: _buildModernDropdown(
                value: _selectedSort,
                items: ['الأقرب', 'الأعلى تقييماً', 'العروض أولاً'],
                onChanged: (val) => setState(() => _selectedSort = val!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModernDropdown(
                value: _selectedCategory,
                items: ['جميع المتاجر', 'رجالي', 'نسائي', 'أطفال'],
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
            ),
          ],
        ),
      ],
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
        color: const Color(0xFF1E5BB3).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF0A1931),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 20),
          isExpanded: true,
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(item, textAlign: TextAlign.right),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

    Widget _buildStoreGrid() {
    final stores = _filteredStores;

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
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoreDetailsScreen(
                    storeName: store['name'],
                    storeCategory: store['category'],
                    storeRating: store['rating'],
                    storeDistance: store['distance'],
                    storeImageUrl: store['imageUrl'],
                  ),
                ),
              );
            },
            child: _buildStoreCard(
              name: store['name'],
              category: store['category'],
              rating: store['rating'],
              distance: store['distance'],
              imageUrl: store['imageUrl'],
              discount: store['discount'],
            ),
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
