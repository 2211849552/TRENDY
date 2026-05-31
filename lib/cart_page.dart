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
import 'data/product_color_variants.dart';
import 'widgets/store_cover_image.dart';
import 'widgets/gradient_button.dart';

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
  final Set<CartItem> _selectedItems = {};
  String _search = '';

  static const _availableSizes = ['S', 'M', 'L', 'XL', 'XXL'];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_cartManager, AppLocale.instance, AppThemeMode.instance]),
      builder: (context, _) {
        bool isEmpty = _cartManager.items.isEmpty;

        return Container(
          color: context.trendy.pageBackground,
          padding: const EdgeInsets.symmetric(horizontal: 24),
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
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFA855F7).withOpacity(0.3),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Products List on the RIGHT (shown first in RTL Row)
        Expanded(
          flex: 2,
          child: ListView.builder(
            itemCount: storeItems.length,
            itemBuilder: (context, index) {
              return _buildCartItemCard(storeItems[index]);
            },
          ),
        ),
        const SizedBox(width: 24),
        // Order Summary on the LEFT (shown second in RTL Row)
        Expanded(
          flex: 1,
          child: _buildOrderSummary(storeName, storeItems),
        ),
      ],
    );
  }

  Widget _buildOrderSummary(String storeName, List<CartItem> storeItems) {
    final selectedStoreItems = storeItems.where((e) => _selectedItems.contains(e)).toList();
    final activeItems = selectedStoreItems.isEmpty ? storeItems : selectedStoreItems;
    final productsTotal = activeItems.fold(0.0, (sum, item) => sum + item.totalPrice);
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
          GradientButton(
            onPressed: () {
              if (widget.isGuest) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              } else {
                _goToCheckout(storeName, activeItems, productsTotal, deliveryFee);
              }
            },
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Text(
                  '${grandTotal.toStringAsFixed(0)}$suffix',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.isGuest
                        ? context.tr('cart_login_prompt')
                        : context.tr('continue_btn'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                if (_selectedItems.isEmpty) {
                  _cartManager.clearCart();
                } else {
                  for (final item in _selectedItems.toList()) {
                    _cartManager.removeFromCart(item);
                  }
                  setState(() => _selectedItems.clear());
                }
              },
              child: Text(
                _selectedItems.isEmpty ? context.tr('cart_clear') : context.tr('clear_selected_items'),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.cairo(fontSize: fontSize, color: color)),
        Text(value, style: GoogleFonts.cairo(fontSize: fontSize + 2, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }

  Widget _buildCartItemCard(CartItem item) {
    final isSelected = _selectedItems.contains(item);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFA855F7).withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          // 1. Info and text on the LEFT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: isSelected,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selectedItems.add(item);
                          } else {
                            _selectedItems.remove(item);
                          }
                        });
                      },
                    ),
                    Text(context.tr('select_item'), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                Text(
                  context.tr(item.product.name),
                  style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                _buildEditableAttributeRow(
                  label: context.tr('color'),
                  value: context.tr(item.selectedColor),
                  onTap: () => _showColorPicker(item),
                ),
                const SizedBox(height: 4),
                _buildEditableAttributeRow(
                  label: context.tr('size'),
                  value: item.selectedSize,
                  onTap: () => _showSizePicker(item),
                ),
                const SizedBox(height: 16),
                Text(
                  '${item.product.price}${context.tr('currency_suffix')}',
                  style: GoogleFonts.cairo(fontSize: 20, color: const Color(0xFF3B82F6), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // 2. Actions (Trash and counter) in the MIDDLE
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                onPressed: () => _cartManager.removeFromCart(item),
              ),
              const SizedBox(height: 12),
              _buildQuantityCounter(item),
            ],
          ),

          const SizedBox(width: 20),

          // 3. Image on the RIGHT — نفس صورة المنتج دائماً؛ اللون في الوصف فقط
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: StoreCoverImage(
              imageUrl: item.product.imageUrl,
              height: 100,
              width: 100,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityCounter(CartItem item) {
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
            icon: const Icon(Icons.add, color: const Color(0xFF3B82F6), size: 16),
            onPressed: () => _cartManager.updateQuantity(item, 1),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableAttributeRow({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
            Text(
              value,
              style: GoogleFonts.cairo(
                color: const Color(0xFF3B82F6),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF3B82F6)),
          ],
        ),
      ),
    );
  }

  Future<void> _showColorPicker(CartItem item) async {
    final colors = ProductColorVariants.colorsFor(item.product.name);
    var selected = colors.contains(item.selectedColor)
        ? item.selectedColor
        : ProductColorVariants.defaultColorFor(item.product.name);

    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1E1B4B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('edit_color_title'),
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: StoreCoverImage(
                  imageUrl: item.product.imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: colors.map((color) {
                  final isSelected = selected == color;
                  return GestureDetector(
                    onTap: () => setSheetState(() => selected = color),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFA855F7).withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF3B82F6) : Colors.white10,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        context.tr(color),
                        style: GoogleFonts.cairo(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA855F7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    context.tr('save_changes'),
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (picked != null && picked != item.selectedColor && mounted) {
      _cartManager.updateAttributes(item, color: picked);
      setState(() {});
    }
  }

  Future<void> _showSizePicker(CartItem item) async {
    var selected = _availableSizes.contains(item.selectedSize) ? item.selectedSize : 'M';

    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1E1B4B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('edit_size_title'),
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _availableSizes.map((size) {
                  final isSelected = selected == size;
                  return GestureDetector(
                    onTap: () => setSheetState(() => selected = size),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFA855F7) : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF3B82F6) : Colors.white10,
                        ),
                      ),
                      child: Text(
                        size,
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA855F7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    context.tr('save_changes'),
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (picked != null && picked != item.selectedSize && mounted) {
      _cartManager.updateAttributes(item, size: picked);
      setState(() {});
    }
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
