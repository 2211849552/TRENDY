import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'locale/app_locale.dart';
import 'theme/app_theme_mode.dart';
import 'theme/trendy_theme_extension.dart';
import 'l10n/app_strings.dart';
import 'models/cart_manager.dart';
import 'models/cart_item.dart';
import 'login_screen.dart';
import 'data/store_catalog.dart';
import 'data/store_delivery.dart';
import 'checkout/order_details_screen.dart';
import 'widgets/app_back_button.dart';
import 'widgets/store_cover_image.dart';
import 'widgets/gradient_button.dart';
import 'widgets/trendy_brand.dart';

class CartPage extends StatefulWidget {
  final VoidCallback onBrowseStores;
  /// يُستدعى بعد إتمام الطلب للانتقال إلى تبويب الطلبات.
  final VoidCallback onOrderPlaced;
  final bool isGuest;

  const CartPage({
    super.key,
    required this.onBrowseStores,
    required this.onOrderPlaced,
    this.isGuest = false,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartManager _cartManager = CartManager();
  String _search = '';

  @override
  void initState() {
    super.initState();
    if (!widget.isGuest) {
      _cartManager.syncFromApi();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_cartManager, AppLocale.instance, AppThemeMode.instance]),
      builder: (context, _) {
        bool isEmpty = _cartManager.items.isEmpty;

        return Container(
          color: context.trendy.pageBackground,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Directionality(
            textDirection: context.isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildBrandingHeader(),
                const SizedBox(height: 32),
                _buildPageHeader(isEmpty),
                const SizedBox(height: 24),
                
                Expanded(
                  child: isEmpty 
                    ? _buildEmptyState() 
                    : _buildCartContent(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBrandingHeader() {
    return const Center(
      child: TrendyBrandBadge(
        textSize: 24,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        borderRadius: 12,
      ),
    );
  }

  Widget _buildPageHeader(bool isEmpty) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.65),
          child: AppBackIconButton(
            onPressed: widget.onBrowseStores,
          ),
        ),
        Text(
          context.tr('cart_title'),
          style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: context.trendy.titleColor),
        ),
      ],
    );
  }

  Widget _buildCartContent() {
    final filteredItems = _cartManager.items.where((item) {
      if (_search.trim().isEmpty) return true;
      final q = _search.trim().toLowerCase();
      return context.tr(item.product.name).toLowerCase().contains(q) ||
          (item.product.code ?? '').toLowerCase().contains(q);
    }).toList();

    if (filteredItems.isEmpty) {
      return Center(
        child: Text(
          context.tr('search_no_result'),
          style: GoogleFonts.cairo(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    final storeKey = _cartManager.currentStoreKey!;
    return _buildStoreCartView(storeKey, filteredItems);
  }

  Widget _buildStoreCartView(String storeName, List<CartItem> storeItems) {
    return ListView(
      children: [
        ...storeItems.map(_buildCartItemCard),
        const SizedBox(height: 8),
        _buildOrderSummary(storeName, storeItems),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildOrderSummary(String storeName, List<CartItem> storeItems) {
    final productsTotal = storeItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    final deliveryFee = _deliveryFeeForStore(storeName);
    final grandTotal = productsTotal + deliveryFee;
    final suffix = context.tr('currency_suffix');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFA855F7).withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('cart_summary'),
            style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('invoice_title'),
            style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            context.tr('cart_items_price'),
            '${productsTotal.toStringAsFixed(0)}$suffix',
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            context.tr('cart_delivery_price'),
            '${deliveryFee.toStringAsFixed(0)}$suffix',
          ),
          const Divider(color: Colors.white10, height: 32),
          _buildSummaryRow(
            context.tr('cart_total'),
            '${grandTotal.toStringAsFixed(0)}$suffix',
            valueColor: const Color(0xFF3B82F6),
            fontSize: 16,
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Text(
                  '${grandTotal.toStringAsFixed(0)}$suffix',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF3B82F6),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (widget.isGuest) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                      } else {
                        _goToCheckout(storeName, storeItems, productsTotal, deliveryFee);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA855F7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_basket_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          widget.isGuest
                              ? context.tr('cart_login_prompt')
                              : context.tr('continue_btn'),
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => _cartManager.clearCart(),
              child: Text(
                context.tr('cart_clear'),
                style: GoogleFonts.cairo(color: const Color(0xFF3B82F6), fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _deliveryFeeForStore(String storeKey) {
    final store = StoreCatalog.findByKey(storeKey);
    if (store == null) return 5.0;
    return StoreDelivery.feeFor(store);
  }

  void _goToCheckout(
    String storeName,
    List<CartItem> activeItems,
    double productsTotal,
    double deliveryFee,
  ) {
    OrderDetailsScreen.show(
      context,
      storeKey: storeName,
      items: activeItems,
      productsTotal: productsTotal,
      deliveryFee: deliveryFee,
      onOrderPlaced: widget.onOrderPlaced,
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color color = Colors.white70, Color valueColor = Colors.white, double fontSize = 16}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.cairo(fontSize: fontSize, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: fontSize + 2,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  String _localizedOrRaw(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    final translated = context.tr(trimmed);
    return translated == trimmed ? trimmed : translated;
  }

  String _variantLine(CartItem item) {
    final parts = <String>[];
    if (item.selectedColor.trim().isNotEmpty) {
      parts.add(_localizedOrRaw(item.selectedColor));
    }
    if (item.selectedSize.trim().isNotEmpty) {
      parts.add(item.selectedSize);
    }
    return parts.join(' • ');
  }

  Widget _buildCartItemCard(CartItem item) {
    final variantLine = _variantLine(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFA855F7).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: StoreCoverImage(
                  imageUrl: item.product.imageUrl,
                  height: 88,
                  width: 88,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localizedOrRaw(item.product.name),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    if (variantLine.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        variantLine,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${item.product.price}${context.tr('currency_suffix')}',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        color: const Color(0xFF3B82F6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                onPressed: () => _cartManager.removeFromCart(item),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _buildQuantityCounter(item),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityCounter(CartItem item) {
    final maxStock = item.availableStock;
    final canIncrease = maxStock == null || maxStock <= 0 || item.quantity < maxStock;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.white54, size: 16),
            onPressed: () => _cartManager.updateQuantity(item, -1),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '${item.quantity}',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.add,
              color: canIncrease ? const Color(0xFF3B82F6) : Colors.white24,
              size: 16,
            ),
            onPressed: canIncrease
                ? () async {
                    await _cartManager.updateQuantity(item, 1);
                    if (!mounted) return;
                    if (_cartManager.error == 'max_quantity_reached') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.tr('max_quantity_reached'), style: GoogleFonts.cairo()),
                        ),
                      );
                    }
                  }
                : null,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final t = context.trendy;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shopping_basket_outlined, size: 100, color: t.subtitleColor.withValues(alpha: 0.45)),
        const SizedBox(height: 24),
        Text(
          context.tr('cart_empty'),
          style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: t.titleColor),
        ),
        const SizedBox(height: 32),
        GradientButton(
          onPressed: widget.onBrowseStores,
          label: context.tr('cart_shop_now'),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        ),
      ],
    );
  }
}
