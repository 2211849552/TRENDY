import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/cart_manager.dart';
import 'models/cart_item.dart';
import 'login_screen.dart';

class CartPage extends StatefulWidget {
  final VoidCallback onBrowseStores;
  final bool isGuest;

  const CartPage({super.key, required this.onBrowseStores, this.isGuest = false});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartManager _cartManager = CartManager();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _cartManager,
      builder: (context, _) {
        bool isEmpty = _cartManager.items.isEmpty;

        return Container(
          color: const Color(0xFF0A1931),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Directionality(
            textDirection: TextDirection.rtl,
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
          color: const Color(0xFF1E5BB3).withValues(alpha: 0.3),
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
        TextButton.icon(
          onPressed: widget.onBrowseStores,
          icon: const Icon(Icons.arrow_forward, color: Colors.white70, size: 18),
          label: const Text(
            'رجوع',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
        ),
        Text(
          'سلة التسوق',
          style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildCartContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Products List on the RIGHT (shown first in RTL Row)
        Expanded(
          flex: 2,
          child: ListView.builder(
            itemCount: _cartManager.items.length,
            itemBuilder: (context, index) {
              return _buildCartItemCard(_cartManager.items[index]);
            },
          ),
        ),
        const SizedBox(width: 24),
        // Order Summary on the LEFT (shown second in RTL Row)
        Expanded(
          flex: 1,
          child: _buildOrderSummary(),
        ),
      ],
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E5BB3).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ملخص الطلب',
            style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 32),
          _buildSummaryRow('عدد المنتجات', '${_cartManager.totalItems}'),
          const SizedBox(height: 16),
          _buildSummaryRow('الإجمالي', '${_cartManager.totalPrice} د.ل', valueColor: Colors.blueAccent),
          const Divider(color: Colors.white10, height: 40),
          if (!widget.isGuest) ...[
            _buildSummaryRow('رصيد المحفظة: 100 د.ل', '', fontSize: 14, color: Colors.white54),
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
                  // TODO: Implement regular checkout
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isGuest ? Colors.blueAccent : const Color(0xFF1E5BB3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                widget.isGuest ? 'تسجيل الدخول لإتمام الطلب' : 'الدفع عبر المحفظة',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => _cartManager.clearCart(),
              child: Text(
                'تفريغ السلة',
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
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E5BB3).withValues(alpha: 0.1),
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
                Text(
                  item.product.name,
                  style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'اللون: ${item.selectedColor}، المقاس: ${item.selectedSize}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Text(
                  '${item.product.price} د.ل',
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
        color: Colors.white.withValues(alpha: 0.05),
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

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shopping_basket_outlined, size: 100, color: Colors.white.withValues(alpha: 0.2)),
        const SizedBox(height: 24),
        Text(
          'سلة التسوق فارغة',
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
              'ابدأ التسوق الآن',
              style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
