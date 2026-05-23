import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'notifications_screen.dart';
import 'favorites_page.dart';
import 'cart_page.dart';
import 'models/favorites_manager.dart';
import 'models/cart_manager.dart';
import 'models/cart_item.dart';
import 'models/order.dart';
import 'models/orders_manager.dart';
import 'models/wallet_manager.dart';
import 'models/notification_manager.dart';
import 'models/notification_item.dart';
import 'models/ratings_manager.dart';
import 'services/location_service.dart';
import 'services/store_location.dart';
import 'orders_page.dart';
import 'settings_page.dart';
import 'locale/app_locale.dart';
import 'l10n/app_strings.dart';
import 'data/store_catalog.dart';
import 'data/campaign_visuals.dart';
import 'theme/app_theme_mode.dart';
import 'theme/trendy_theme_extension.dart';
import 'models/marketing_campaign.dart';
import 'models/marketing_campaigns_manager.dart';
import 'utils/store_navigation.dart';
import 'widgets/campaign_promo_dialog.dart';
import 'widgets/store_cover_image.dart';

class HomeScreen extends StatefulWidget {
  final bool isGuest;
  final String userName;
  const HomeScreen({super.key, this.isGuest = false, this.userName = 'hajer'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _cardExtent = 280;
  static const double _gridGap = 20;

  final FavoritesManager _favoritesManager = FavoritesManager();
  final CartManager _cartManager = CartManager();
  final OrdersManager _ordersManager = OrdersManager();
  final RatingsManager _ratingsManager = RatingsManager();
  final LocationService _locationService = const LocationService();
  int _selectedIndex = 0;
  String _searchQuery = "";
  /// مفاتيح داخلية ثابتة — التسميات تُعرَض عبر [tr] حسب اللغة.
  String _selectedStoreTypeKey = 'all';
  String _selectedSortKey = 'nearest';
  bool _isLocating = false;
  double? _userLat;
  double? _userLng;

  final MarketingCampaignsManager _campaignsManager = MarketingCampaignsManager();

  List<Map<String, dynamic>> get _stores => StoreCatalog.stores;

  @override
  void initState() {
    super.initState();
    _refreshUserLocation();
  }

  Future<void> _refreshUserLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    try {
      final pos = await _locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _userLat = pos?.latitude;
        _userLng = pos?.longitude;
      });
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  double? _liveDistanceKmForStore(Map<String, dynamic> store) {
    final lat = _userLat;
    final lng = _userLng;
    final loc = store['location'] as StoreLocation?;
    if (lat == null || lng == null || loc == null) return null;
    return _locationService.distanceKm(
      fromLat: lat,
      fromLng: lng,
      toLat: loc.lat,
      toLng: loc.lng,
    );
  }

  String _distanceTextForStore(Map<String, dynamic> store) {
    final live = _liveDistanceKmForStore(store);
    if (live != null) return live.toStringAsFixed(1);

    final fallback = store['displayDistanceKm'] as num?;
    if (fallback != null) return fallback.toStringAsFixed(1);

    return '--';
  }

  SliverGridDelegateWithFixedCrossAxisCount get _homeGridDelegate {
    return const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisSpacing: _gridGap,
      crossAxisSpacing: _gridGap,
      mainAxisExtent: _cardExtent,
    );
  }

  List<Map<String, dynamic>> get _filteredStores {
    List<Map<String, dynamic>> filtered = _stores.where((store) {
      final q = _searchQuery.toLowerCase();
      final translatedName = context.tr(store['name']).toLowerCase();
      final translatedCategory = context.tr(store['category']).toLowerCase();
      final nameMatches = translatedName.contains(q) || translatedCategory.contains(q);
      
      final isElectronic = store['isElectronic'] as bool? ?? false;
      bool typeMatches = _selectedStoreTypeKey == 'all';
      if (_selectedStoreTypeKey == 'electronic') {
        typeMatches = isElectronic;
      } else if (_selectedStoreTypeKey == 'non_electronic') {
        typeMatches = !isElectronic;
      }

      return nameMatches && typeMatches;
    }).toList();

    // Apply Sorting
    if (_selectedSortKey == 'rating') {
      filtered.sort((a, b) {
        final aRating = _ratingsManager.storeRatingOrBase(
          a['name'].toString(),
          (a['rating'] as num).toDouble(),
        );
        final bRating = _ratingsManager.storeRatingOrBase(
          b['name'].toString(),
          (b['rating'] as num).toDouble(),
        );
        return bRating.compareTo(aRating);
      });
    } else if (_selectedSortKey == 'nearest') {
      filtered.sort((a, b) {
        final distA = _liveDistanceKmForStore(a) ?? (a['displayDistanceKm'] as num?)?.toDouble() ?? 9999;
        final distB = _liveDistanceKmForStore(b) ?? (b['displayDistanceKm'] as num?)?.toDouble() ?? 9999;
        return distA.compareTo(distB);
      });
    }

    return filtered;
  }

  void _onWalletCheckout(String storeName, [List<CartItem>? selectedItems]) {
    if (_cartManager.items.isEmpty) return;

    final storeItems = (selectedItems ?? _cartManager.items)
        .where((item) => item.product.storeName == storeName)
        .toList();
    if (storeItems.isEmpty) return;

    double total = storeItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    
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
    final items = storeItems
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
        status: 'status_pending',
        storeName: storeName,
        paymentMethod: 'wallet',
      ),
    );
    setState(() => _selectedIndex = 3);
    for (var item in storeItems) {
      _cartManager.removeFromCart(item);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr('order_confirmed'),
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: const Color(0xFFA855F7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.trendy.pageBackground,
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
              _buildWelcomeBanner(),
              const SizedBox(height: 20),
              _buildAdCampaignsSection(),
              const SizedBox(height: 20),
              _buildSearchSection(),
              const SizedBox(height: 24),
              // Stores Section Title
              Text(
                '${context.tr('stores_available')} (${_filteredStores.length})',
                textAlign: context.isRtl ? TextAlign.right : TextAlign.left,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: context.trendy.titleColor,
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
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Trendy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: context.trendy.titleColor,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.checkroom_rounded, color: Color(0xFF3B82F6), size: 24),
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
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.95),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.85),
          ],
        ),
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
          // Left side: notifications only
          GestureDetector(
            onTap: () async {
              final tapped = await Navigator.push<NotificationItem?>(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
              if (!mounted) return;
              if (tapped != null && tapped.targetTab == 'orders') {
                setState(() => _selectedIndex = 3);
              }
            },
            child: ListenableBuilder(
              listenable: NotificationManager(),
              builder: (context, _) {
                final unread = NotificationManager().unreadCount;
                return Stack(
                  clipBehavior: Clip.none,
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

  Widget _buildAdCampaignsSection() {
    final campaigns = _campaignsManager.homeFeatured;
    if (campaigns.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final cellWidth = (constraints.maxWidth - 32 - gap * 2) / 3;
        final cardHeight = (cellWidth * 1.55).clamp(155.0, 195.0);

        return Container(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
          decoration: BoxDecoration(
            gradient: CampaignVisuals.sectionGradient,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: CampaignVisuals.sectionBorder),
            boxShadow: const [
              BoxShadow(
                color: CampaignVisuals.sectionGlow,
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.campaign, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr('home_ad_campaigns'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: gap,
                  crossAxisSpacing: gap,
                  mainAxisExtent: cardHeight,
                ),
                itemCount: campaigns.length,
                itemBuilder: (context, index) {
                  final campaign = campaigns[index];
                  return _HomeCampaignCard(
                    campaign: campaign,
                    cardHeight: cardHeight,
                    visual: CampaignVisuals.forCampaign(campaign.id),
                    onOpenDetails: () => CampaignPromoDialog.show(
                      context,
                      campaign: campaign,
                      userLat: _userLat,
                      userLng: _userLng,
                    ),
                    onStoreTap: (storeKey) => StoreNavigation.open(
                      context,
                      storeKey: storeKey,
                      userLat: _userLat,
                      userLng: _userLng,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
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
            prefixIcon: const Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 16),
        // Filter Dropdowns
        Row(
          children: [
            Expanded(
              child: _buildModernDropdown(
                value: _selectedStoreTypeKey,
                itemKeys: const ['all', 'electronic', 'non_electronic'],
                labelForKey: (k) {
                  switch (k) {
                    case 'all':
                      return context.tr('filter_all_types');
                    case 'electronic':
                      return context.tr('filter_electronic_stores');
                    case 'non_electronic':
                      return context.tr('filter_non_electronic_stores');
                    default:
                      return k;
                  }
                },
                onChanged: (val) => setState(() => _selectedStoreTypeKey = val!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModernDropdown(
                value: _selectedSortKey,
                itemKeys: const ['nearest', 'rating'],
                labelForKey: (k) {
                  switch (k) {
                    case 'nearest':
                      return context.tr('sort_nearest');
                    case 'rating':
                      return context.tr('sort_rating');
                    default:
                      return k;
                  }
                },
                onChanged: (val) => setState(() => _selectedSortKey = val!),
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
    final trendy = context.trendy;
    final align = context.isRtl ? Alignment.centerRight : Alignment.centerLeft;
    final tAlign = context.isRtl ? TextAlign.right : TextAlign.left;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: trendy.cardFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: trendy.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: trendy.surfaceColor,
          icon: Icon(Icons.keyboard_arrow_down, color: trendy.subtitleColor, size: 20),
          isExpanded: true,
          style: GoogleFonts.cairo(
            color: trendy.titleColor,
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
      gridDelegate: _homeGridDelegate,
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final store = stores[index];
          final distText = _distanceTextForStore(store);
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: GestureDetector(
            onTap: () {
              StoreNavigation.open(
                context,
                storeKey: store['name'] as String,
                userLat: _userLat,
                userLng: _userLng,
              );
            },
            child: _buildStoreCard(
              name: store['name'],
              rating: _ratingsManager.storeRatingOrBase(
                store['name'].toString(),
                (store['rating'] as num).toDouble(),
              ),
              distance: distText,
              imageUrl: store['imageUrl'],
              discount: store['discount'],
              isElectronic: store['isElectronic'] as bool? ?? false,
            ),
            ),
          );
        },
        childCount: stores.length,
      ),
    );
  }

  Widget _buildStoreCard({
    required String name,
    required double rating,
    required String distance,
    required String imageUrl,
    required bool isElectronic,
    String? discount,
  }) {
    final trendy = context.trendy;
    final typeColor = isElectronic ? Colors.greenAccent : Colors.orangeAccent;
    final typeIcon = isElectronic ? Icons.smartphone_outlined : Icons.storefront_outlined;
    final typeLabel = isElectronic
        ? context.tr('store_type_electronic')
        : context.tr('store_type_physical');
    return Container(
      decoration: BoxDecoration(
        color: trendy.cardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: trendy.cardBorder),
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
                  child: StoreCoverImage(
                    imageUrl: imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
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
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_offer_outlined, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            context.tr('discount_up_to').replaceAll('{percent}', discount),
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
                  context.tr(name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: trendy.titleColor,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _storeMetaChip(
                        icon: typeIcon,
                        iconColor: typeColor,
                        label: typeLabel,
                        labelColor: typeColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _storeMetaChip(
                        icon: Icons.location_on_outlined,
                        iconColor: const Color(0xFF3B82F6),
                        label: '$distance${context.tr('km_suffix')}',
                        labelColor: trendy.subtitleColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _storeMetaChip(
                        icon: Icons.star,
                        iconColor: Colors.amber,
                        label: rating.toStringAsFixed(1),
                        labelColor: trendy.titleColor,
                        iconAfterLabel: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _storeMetaChip({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color labelColor,
    bool iconAfterLabel = false,
  }) {
    final iconWidget = Icon(icon, color: iconColor, size: 12);
    final textWidget = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: GoogleFonts.cairo(color: labelColor, fontSize: 9, fontWeight: FontWeight.w600),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: iconAfterLabel
          ? [Flexible(child: textWidget), const SizedBox(width: 2), iconWidget]
          : [iconWidget, const SizedBox(width: 2), Flexible(child: textWidget)],
    );
  }

  Widget _buildBottomNav() {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _favoritesManager,
        _cartManager,
        _ordersManager,
        _ratingsManager,
        AppLocale.instance,
        AppThemeMode.instance,
      ]),
      builder: (context, _) {
        final navTheme = Theme.of(context).bottomNavigationBarTheme;
        return BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: navTheme.backgroundColor,
          selectedItemColor: navTheme.selectedItemColor,
          unselectedItemColor: navTheme.unselectedItemColor,
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
                color: const Color(0xFF3B82F6),
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

class _HomeCampaignCard extends StatelessWidget {
  final MarketingCampaign campaign;
  final double cardHeight;
  final CampaignVisual visual;
  final VoidCallback onOpenDetails;
  final void Function(String storeKey) onStoreTap;

  const _HomeCampaignCard({
    required this.campaign,
    required this.cardHeight,
    required this.visual,
    required this.onOpenDetails,
    required this.onStoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final badge = campaign.badgeKey != null ? context.tr(campaign.badgeKey!) : null;
    final imageUrl = campaign.imageUrl ?? visual.imageUrl;
    final storeColor = Theme.of(context).colorScheme.primary;
    final stores = campaign.storeKeys.take(2).toList();

    return GestureDetector(
      onTap: onOpenDetails,
      child: SizedBox(
        height: cardHeight,
        child: Container(
          decoration: BoxDecoration(
            gradient: visual.cardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: storeColor.withValues(alpha: 0.35), width: 1.2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 7,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: visual.gradientEnd),
                    if (imageUrl != null)
                      Positioned.fill(
                        child: StoreCoverImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    if (badge != null)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: visual.badgeColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            badge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        campaign.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.15,
                        ),
                      ),
                      const Spacer(),
                      ...stores.map(
                        (key) => GestureDetector(
                          onTap: () => onStoreTap(key),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Text(
                              context.tr(key),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: GoogleFonts.cairo(
                                color: storeColor,
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
