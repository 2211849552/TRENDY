import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'locale/app_locale.dart';
import 'l10n/app_strings.dart';
import 'models/cart_manager.dart';
import 'models/cart_item.dart';
import 'models/wallet_manager.dart';
import 'models/orders_manager.dart';
import 'login_screen.dart';
import 'widgets/app_back_button.dart';

class CartPage extends StatefulWidget {
  final VoidCallback onBrowseStores;
  /// يُنفَّذ من الشاشة الأم لضمان التبديل إلى تبويب الطلبات مباشرة بعد الدفع.
  final void Function(String, [List<CartItem>?]) onWalletPay;
  final bool isGuest;

  const CartPage({
    super.key,
    required this.onBrowseStores,
    required this.onWalletPay,
    this.isGuest = false,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartManager _cartManager = CartManager();
  final Set<CartItem> _selectedItems = {};
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_cartManager, WalletManager(), AppLocale.instance]),
      builder: (context, _) {
        bool isEmpty = _cartManager.items.isEmpty;

        return Container(
          color: const Color(0xFF0A1931),
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
          color: const Color(0xFF1E5BB3).withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Trendy',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(width: 8),
            Icon(Icons.checkroom_rounded, color: Colors.blueAccent, size: 24),
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
          style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildCartContent() {
    Map<String, List<CartItem>> itemsByStore = {};
    final filteredItems = _cartManager.items.where((item) {
      if (_search.trim().isEmpty) return true;
      final q = _search.trim().toLowerCase();
      return context.tr(item.product.name).toLowerCase().contains(q) ||
          (item.product.code ?? '').toLowerCase().contains(q);
    }).toList();
    for (var item in filteredItems) {
      itemsByStore.putIfAbsent(item.product.storeName, () => []).add(item);
    }
    final storeNames = itemsByStore.keys.toList();

    if (storeNames.length == 1) {
      return _buildStoreCartView(storeNames.first, itemsByStore[storeNames.first]!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: (v) => setState(() => _search = v),
          style: GoogleFonts.cairo(color: Colors.white),
          decoration: InputDecoration(
            hintText: context.tr('search_product_cart'),
            hintStyle: GoogleFonts.cairo(color: Colors.white30),
            prefixIcon: const Icon(Icons.search, color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF1E5BB3).withOpacity(0.12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E5BB3).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            context.tr('multi_store_warning'),
            style: GoogleFonts.cairo(color: Colors.amber, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            TextButton(
              onPressed: () => setState(() => _selectedItems.addAll(filteredItems)),
              child: Text(context.tr('select_all_items')),
            ),
            TextButton(
              onPressed: () => setState(_selectedItems.clear),
              child: Text(context.tr('unselect_all_items')),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: DefaultTabController(
            length: storeNames.length,
            child: Column(
              children: [
                TabBar(
                  isScrollable: true,
                  indicatorColor: Colors.blueAccent,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  tabs: storeNames.map((name) => Tab(text: context.tr(name))).toList(),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    children: storeNames.map((name) {
                      return _buildStoreCartView(name, itemsByStore[name]!);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
    int totalItems = activeItems.fold(0, (sum, item) => sum + item.quantity);
    double totalPrice = activeItems.fold(0.0, (sum, item) => sum + item.totalPrice);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E5BB3).withOpacity(0.1),
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
          const SizedBox(height: 32),
          _buildSummaryRow(context.tr('cart_items_count'), '$totalItems'),
          const SizedBox(height: 16),
          _buildSummaryRow(
            context.tr('cart_total'),
            '$totalPrice${context.tr('currency_suffix')}',
            valueColor: Colors.blueAccent,
          ),
          const Divider(color: Colors.white10, height: 40),
          if (!widget.isGuest) ...[
            _buildSummaryRow(
              context.tr('cart_wallet_balance'),
              '${WalletManager().balance.toStringAsFixed(2)}${context.tr('currency_suffix')}',
              fontSize: 14,
              color: Colors.white54,
            ),
            const SizedBox(height: 24),
          ] else ...[
            const SizedBox(height: 16),
          ],
          
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                if (widget.isGuest) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                } else {
                  if (!OrdersManager().canCheckoutFromStore(storeName)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.tr('multi_store_error'),
                          style: GoogleFonts.cairo(),
                        ),
                        backgroundColor: Colors.redAccent.shade700,
                      ),
                    );
                    return;
                  }
                  widget.onWalletPay(storeName, activeItems);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isGuest ? Colors.blueAccent : const Color(0xFF1E5BB3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                widget.isGuest ? context.tr('cart_login_prompt') : context.tr('cart_pay_wallet'),
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
              ),
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
                style: GoogleFonts.cairo(color: Colors.blueAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
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
        color: const Color(0xFF1E5BB3).withOpacity(0.1),
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
                Text(
                  '${context.tr('color')}: ${item.selectedColor}, ${context.tr('size')}: ${item.selectedSize}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                TextButton.icon(
                  onPressed: () => _showEditAttributesDialog(item),
                  icon: const Icon(Icons.tune, size: 16, color: Colors.blueAccent),
                  label: Text(context.tr('edit_item_attributes'), style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
                ),
                const SizedBox(height: 16),
                Text(
                  '${item.product.price}${context.tr('currency_suffix')}',
                  style: GoogleFonts.cairo(fontSize: 20, color: Colors.blueAccent, fontWeight: FontWeight.bold),
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

          // 3. Image on the RIGHT
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              item.product.imageUrl,
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
            icon: const Icon(Icons.add, color: Colors.blueAccent, size: 16),
            onPressed: () => _cartManager.updateQuantity(item, 1),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _showEditAttributesDialog(CartItem item) {
    final colorController = TextEditingController(text: item.selectedColor);
    final sizeController = TextEditingController(text: item.selectedSize);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF121E36),
        title: Text(context.tr('edit_item_attributes'), style: GoogleFonts.cairo(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: colorController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(hintText: context.tr('color')),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: sizeController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(hintText: context.tr('size')),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('cancel'))),
          ElevatedButton(
            onPressed: () {
              _cartManager.updateAttributes(
                item,
                color: colorController.text.trim(),
                size: sizeController.text.trim(),
              );
              Navigator.pop(ctx);
            },
            child: Text(context.tr('save_changes')),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shopping_basket_outlined, size: 100, color: Colors.white.withOpacity(0.2)),
        const SizedBox(height: 24),
        Text(
          context.tr('cart_empty'),
          style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: 180,
          height: 50,
          child: ElevatedButton(
            onPressed: widget.onBrowseStores,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E5BB3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text(
              context.tr('cart_shop_now'),
              style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
