import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/cart_item.dart';
import 'models/cart_manager.dart';
import 'models/order.dart';
import 'models/orders_manager.dart';
import 'locale/app_locale.dart';
import 'l10n/app_strings.dart';

class OrdersPage extends StatefulWidget {
  final VoidCallback onBrowseStores;

  const OrdersPage({super.key, required this.onBrowseStores});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final OrdersManager _ordersManager = OrdersManager();
  final CartManager _cartManager = CartManager();

  /// يطابق قيم `Order.status` المعروضة في القائمة المنسدلة
  String _filterLabel = 'status_all';

  String _formatDate(BuildContext context, DateTime d) {
    if (context.isRtl) {
      final day = d.day.toString().padLeft(2, '0');
      final month = AppStrings.of(context, 'month_${d.month}');
      return '$day $month ${d.year}';
    }
    final day = d.day.toString();
    final month = AppStrings.of(context, 'month_${d.month}');
    return '$month $day, ${d.year}';
  }

  List<Order> get _visibleOrders {
    if (_filterLabel == 'status_all') {
      return _ordersManager.orders;
    }
    return _ordersManager.orders.where((o) => o.status == _filterLabel).toList();
  }

  Color _statusBackground(String status) {
    switch (status) {
      case 'status_pending':
        return const Color(0xFFE6B422).withOpacity(0.25);
      case 'status_ready':
        return Colors.green.withOpacity(0.25);
      case 'status_delivered':
        return Colors.blueAccent.withOpacity(0.2);
      default:
        return Colors.white.withOpacity(0.1);
    }
  }

  Color _statusForeground(String status) {
    switch (status) {
      case 'status_pending':
        return const Color(0xFFFFE082);
      case 'status_ready':
        return Colors.lightGreenAccent;
      case 'status_delivered':
        return Colors.lightBlueAccent;
      default:
        return Colors.white70;
    }
  }

  void _simulateReady(Order order) {
    if (order.status != 'status_pending') return;
    _ordersManager.updateOrderStatus(order.id, 'status_ready');
  }

  void _reorder(Order order) {
    try {
      for (final line in order.items) {
        _cartManager.addToCart(
          line.product,
          color: line.selectedColor,
          size: line.selectedSize,
          quantity: line.quantity,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('added_to_cart'), style: GoogleFonts.cairo()),
          backgroundColor: const Color(0xFF1E5BB3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.redAccent.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ordersManager,
      builder: (context, _) {
        final isEmpty = _ordersManager.count == 0;
        final list = _visibleOrders;

        return Container(
          color: const Color(0xFF0A1931),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Directionality(
            textDirection: context.isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 32),
                _buildSubHeader(isEmpty),
                if (!isEmpty) ...[
                  const SizedBox(height: 16),
                  _buildFilterBar(),
                ],
                const SizedBox(height: 24),
                Expanded(
                  child: isEmpty
                      ? _buildEmptyState()
                      : list.isEmpty
                          ? _buildNoMatchesState()
                          : _buildOrdersList(list),
                ),
              ],
            ),
          ),
        );






      },
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

  Widget _buildSubHeader(bool isEmpty) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CircleAvatar(
          backgroundColor: Colors.black38,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: widget.onBrowseStores,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              context.tr('order_history'),
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (!isEmpty)
              Text(
                '${_ordersManager.count} ${context.tr('orders_count')}',
                style: GoogleFonts.cairo(fontSize: 14, color: Colors.white54),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E5BB3).withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filterLabel,
          isExpanded: true,
          dropdownColor: const Color(0xFF152a45),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
          style: GoogleFonts.cairo(color: Colors.white, fontSize: 16),
          items: [
            DropdownMenuItem(value: 'status_all', child: Text(context.tr('status_all'))),
            DropdownMenuItem(value: 'status_pending', child: Text(context.tr('status_pending'))),
            DropdownMenuItem(value: 'status_ready', child: Text(context.tr('status_ready'))),
            DropdownMenuItem(value: 'status_delivered', child: Text(context.tr('status_delivered'))),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _filterLabel = v);
          },
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<Order> orders) {
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) => _buildOrderCard(orders[index]),
    );
  }

  Widget _buildOrderLine(CartItem line) {
    final detail = '${context.tr(line.selectedColor)} • ${line.selectedSize} • ${context.tr('quantity')}: ${line.quantity}';
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(line.product.name),
                  style: GoogleFonts.cairo(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  detail,
                  style: GoogleFonts.cairo(fontSize: 13, color: Colors.white54),
                ),
                const SizedBox(height: 8),
                Text(
                  '${line.totalPrice.toStringAsFixed(0)} د.ل',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              line.product.imageUrl,
              width: 88,
              height: 88,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 88,
                height: 88,
                color: Colors.white10,
                child: const Icon(Icons.image_not_supported_outlined, color: Colors.white24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E5BB3).withOpacity(0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${context.tr('order_hashtag')}#${order.id}',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusBackground(order.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  context.tr(order.status),
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _statusForeground(order.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(context, order.date),
            style: GoogleFonts.cairo(fontSize: 14, color: Colors.white60),
          ),
          for (final item in order.items) _buildOrderLine(item),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('cart_total'),
                style: GoogleFonts.cairo(fontSize: 16, color: Colors.white70),
              ),
              Text(
                '${order.totalPrice.toStringAsFixed(0)}${context.tr('currency_suffix')}',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: order.status == 'status_pending' 
                      ? () => _simulateReady(order)
                      : order.status == 'status_ready'
                          ? () => _ordersManager.updateOrderStatus(order.id, 'status_delivered')
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: order.status == 'status_ready' ? Colors.green : const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white10,
                    disabledForegroundColor: Colors.white38,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    order.status == 'status_pending' 
                        ? context.tr('simulate_ready') 
                        : order.status == 'status_ready'
                            ? context.tr('confirm_delivery')
                            : context.tr('order_delivered_label'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _reorder(order),
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: Text(context.tr('reorder'), style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoMatchesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_alt_off_outlined, size: 64, color: Colors.white.withOpacity(0.35)),
          const SizedBox(height: 16),
          Text(
            context.tr('no_orders_filter'),
            style: GoogleFonts.cairo(fontSize: 18, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _filterLabel = 'status_all'),
            child: Text(context.tr('view_all_orders'), style: GoogleFonts.cairo(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.inventory_2_outlined,
            size: 100,
            color: Colors.white.withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          context.tr('orders_empty'),
          style: GoogleFonts.cairo(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          context.tr('orders_empty_sub'),
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: 200,
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
              context.tr('start_shopping'),
              style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
