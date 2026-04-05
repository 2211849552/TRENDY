import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'complaints_screen.dart';
import 'notifications_screen.dart';
import 'store_details_screen.dart';
import 'favorites_page.dart';
import 'cart_page.dart';
import 'models/favorites_manager.dart';
import 'models/cart_manager.dart';
import 'models/cart_item.dart';
import 'models/order.dart';
import 'models/orders_manager.dart';
import 'models/wallet_manager.dart';
import 'models/notification_manager.dart';
import 'orders_page.dart';
import 'settings_page.dart';
import 'locale/app_locale.dart';
import 'l10n/app_strings.dart';

class HomeScreen extends StatefulWidget {
  final bool isGuest;
  final String userName;
  const HomeScreen({super.key, this.isGuest = false, this.userName = 'hajer'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FavoritesManager _favoritesManager = FavoritesManager();
  final CartManager _cartManager = CartManager();
  final OrdersManager _ordersManager = OrdersManager();
  int _selectedIndex = 0;
  String _searchQuery = "";
  /// مفاتيح داخلية ثابتة — التسميات تُعرَض عبر [tr] حسب اللغة.
  String _selectedCategoryKey = 'all';
  String _selectedSortKey = 'nearest';

  final List<Map<String, dynamic>> _stores = [
    {
      'name': 'store_elegance',
      'category': 'cat_women',
      'rating': 4.8,
      'distance': '2.5',
      'imageUrl': 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&q=80&w=800',
      'discount': '40%',
    },
    {
      'name': 'store_fashion',
      'category': 'cat_men',
      'rating': 4.5,
      'distance': '1.2',
      'imageUrl': 'https://images.unsplash.com/photo-1490114538077-0a7f8cb49891?auto=format&fit=crop&q=80&w=800',
      'discount': null,
    },
    {
      'name': 'store_gentle',
      'category': 'cat_men',
      'rating': 4.6,
      'distance': '0.8',
      'imageUrl': 'https://images.unsplash.com/photo-1593032465175-481ac7f401a0?auto=format&fit=crop&q=80&w=800',
      'discount': '30%',
    },
    {
      'name': 'store_luxury',
      'category': 'cat_women',
      'rating': 4.7,
      'distance': '5.0',
      'imageUrl': 'https://images.unsplash.com/photo-1566174053879-31528523f8ae?auto=format&fit=crop&q=80&w=800',
      'discount': null,
    },
    {
      'name': 'store_kids',
      'category': 'cat_kids',
      'rating': 4.9,
      'distance': '3.8',
      'imageUrl': 'https://images.unsplash.com/photo-1621451537084-482c73073a0f?auto=format&fit=crop&q=80&w=800',
      'discount': '25%',
    },
    {
      'name': 'store_top',
      'category': 'cat_men',
      'rating': 4.9,
      'distance': '2.1',
      'imageUrl': 'https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&q=80&w=800',
      'discount': null,
    },
  ];

  List<Map<String, dynamic>> get _filteredStores {
      final translatedName = context.tr(store['name']).toLowerCase();
      final nameMatches = translatedName.contains(_searchQuery.toLowerCase());
      
      bool categoryMatches = _selectedCategoryKey == 'all';
      if (_selectedCategoryKey == 'men') {
        categoryMatches = store['category'] == 'cat_men';
      } else if (_selectedCategoryKey == 'women') {
        categoryMatches = store['category'] == 'cat_women';
      } else if (_selectedCategoryKey == 'kids') {
        categoryMatches = store['category'] == 'cat_kids';
      }
      
      return nameMatches && categoryMatches;
    }).toList();

    // Apply Sorting
    if (_selectedSortKey == 'rating') {
      filtered.sort((a, b) => b['rating'].compareTo(a['rating']));
    } else if (_selectedSortKey == 'offers') {
      filtered.sort((a, b) {
        if (a['discount'] != null && b['discount'] == null) return -1;
        if (a['discount'] == null && b['discount'] != null) return 1;
        return 0;
      });
    } else if (_selectedSortKey == 'nearest') {
      filtered.sort((a, b) {
        double distA = double.tryParse(a['distance'].toString()) ?? 99.0;
        double distB = double.tryParse(b['distance'].toString()) ?? 99.0;
        return distA.compareTo(distB);
      });
    }

    return filtered;
  }

  void _onWalletCheckout() {
    if (_cartManager.items.isEmpty) return;
    final total = _cartManager.totalPrice;
    final orderId = DateTime.now().millisecondsSinceEpoch.toString();
    if (!WalletManager().payOrderFromWallet(orderId: orderId, amount: total)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('wallet_insufficient'),
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.redAccent.shade700,
        ),
      );
      return;
    }
    final items = _cartManager.items
        .map(
          (e) => CartItem(
            product: e.product,
            selectedColor: e.selectedColor,
            selectedSize: e.selectedSize,
            quantity: e.quantity,
          ),
        )
        .toList();
    _ordersManager.addOrder(
      Order(
        id: orderId,
        date: DateTime.now(),
        items: items,
        totalPrice: total,
        status: 'قيد الانتظار',
      ),
    );
    setState(() => _selectedIndex = 3);
    _cartManager.clearCart();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr('order_confirmed'),
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: const Color(0xFF1E5BB3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1931),
      body: SafeArea(
        child: _buildBody(),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return FavoritesPage(
          onBrowseStores: () => setState(() => _selectedIndex = 0),
        );
      case 2:
        return CartPage(
          isGuest: widget.isGuest,
          onBrowseStores: () => setState(() => _selectedIndex = 0),
          onWalletPay: _onWalletCheckout,
        );
      case 3:
        return OrdersPage(
          onBrowseStores: () => setState(() => _selectedIndex = 0),
        );
      case 4:
        return SettingsPage(
          onBrowseStores: () => setState(() => _selectedIndex = 0),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHomeContent() {
    return CustomScrollView(
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
                '${context.tr('stores_available')} (${_filteredStores.length})',
                textAlign: context.isRtl ? TextAlign.right : TextAlign.left,
                style: const TextStyle(
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
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E5BB3).withOpacity(0.3),
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
                Text(
                  context.tr('home_welcome'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('home_sub'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.isGuest
                      ? context.tr('home_guest')
                      : '${context.tr('home_hello_user')} ${widget.userName}',
                  style: const TextStyle(
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
                child: ListenableBuilder(
                  listenable: NotificationManager(),
                  builder: (context, _) {
                    final unread = NotificationManager().unreadCount;
                    return Stack(
                      children: [
                        _buildBannerIcon(Icons.notifications_none),
                        if (unread > 0)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '$unread',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
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
        color: Colors.white.withOpacity(0.1),
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
          textAlign: context.isRtl ? TextAlign.right : TextAlign.left,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: context.tr('search_store'),
            hintStyle: GoogleFonts.cairo(color: Colors.white30, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: Colors.white30),
            filled: true,
            fillColor: const Color(0xFF1E5BB3).withOpacity(0.2),
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
                value: _selectedSortKey,
                itemKeys: const ['nearest', 'rating', 'offers'],
                labelForKey: (k) {
                  switch (k) {
                    case 'nearest':
                      return context.tr('sort_nearest');
                    case 'rating':
                      return context.tr('sort_rating');
                    case 'offers':
                      return context.tr('sort_offers');
                    default:
                      return k;
                  }
                },
                onChanged: (val) => setState(() => _selectedSortKey = val!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModernDropdown(
                value: _selectedCategoryKey,
                itemKeys: const ['all', 'men', 'women', 'kids'],
                labelForKey: (k) {
                  switch (k) {
                    case 'all':
                      return context.tr('cat_all');
                    case 'men':
                      return context.tr('cat_men');
                    case 'women':
                      return context.tr('cat_women');
                    case 'kids':
                      return context.tr('cat_kids');
                    default:
                      return k;
                  }
                },
                onChanged: (val) => setState(() => _selectedCategoryKey = val!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernDropdown({
    required String value,
    required List<String> itemKeys,
    required String Function(String key) labelForKey,
    required void Function(String?) onChanged,
  }) {
    final align = context.isRtl ? Alignment.centerRight : Alignment.centerLeft;
    final tAlign = context.isRtl ? TextAlign.right : TextAlign.left;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E5BB3).withOpacity(0.2),
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
          items: itemKeys
              .map(
                (key) => DropdownMenuItem(
                  value: key,
                  child: Align(
                    alignment: align,
                    child: Text(labelForKey(key), textAlign: tAlign),
                  ),
                ),
              )
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
                    storeDiscount: store['discount'],
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
        color: const Color(0xFF1E5BB3).withOpacity(0.15),
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
                        color: const Color(0xFF00D1FF).withOpacity(0.8), // Cyan/Light Blue
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${context.tr('sort_offers').split(' ')[0]} $discount', // Simple workaround for "Discount 40%"
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
                  context.tr(category),
                  style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr(name),
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
                  '$distance${context.tr('km_suffix')}',
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
    return ListenableBuilder(
      listenable: Listenable.merge([
        _favoritesManager,
        _cartManager,
        _ordersManager,
        AppLocale.instance,
      ]),
      builder: (context, _) {
        return BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF0A1931),
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.white54,
          selectedLabelStyle: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.cairo(fontSize: 11),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: context.tr('nav_home'),
            ),
            BottomNavigationBarItem(
              icon: _buildBadgeIcon(Icons.favorite_outline, _favoritesManager.count),
              activeIcon: _buildBadgeIcon(Icons.favorite, _favoritesManager.count),
              label: context.tr('nav_favorites'),
            ),
            BottomNavigationBarItem(
              icon: _buildBadgeIcon(Icons.shopping_basket_outlined, _cartManager.totalItems),
              activeIcon: _buildBadgeIcon(Icons.shopping_basket, _cartManager.totalItems),
              label: context.tr('nav_cart'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.inventory_2_outlined),
              activeIcon: const Icon(Icons.inventory_2),
              label: context.tr('nav_orders'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_outlined),
              activeIcon: const Icon(Icons.settings),
              label: context.tr('nav_settings'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBadgeIcon(IconData icon, int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}
