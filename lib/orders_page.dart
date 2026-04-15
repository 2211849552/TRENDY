import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/cart_item.dart';
import 'models/cart_manager.dart';
import 'models/order.dart';
import 'models/orders_manager.dart';
import 'models/ratings_manager.dart';
import 'l10n/app_strings.dart';
import 'widgets/app_back_button.dart';

class OrdersPage extends StatefulWidget {
  final VoidCallback onBrowseStores;

  const OrdersPage({super.key, required this.onBrowseStores});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final OrdersManager _ordersManager = OrdersManager();
  final CartManager _cartManager = CartManager();
  final RatingsManager _ratingsManager = RatingsManager();

  String _statusFilter = 'status_all';
  String _storeFilter = 'all_stores';
  String _paymentFilter = 'all_payments';
  String _dateFilter = 'all_dates';
  String _orderSearch = '';

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
    final q = _orderSearch.trim().toLowerCase();
    return _ordersManager.orders.where((o) {
      final statusMatch = _statusFilter == 'status_all' || o.status == _statusFilter;
      final storeMatch = _storeFilter == 'all_stores' || o.storeName == _storeFilter;
      final paymentMatch = _paymentFilter == 'all_payments' || o.paymentMethod == _paymentFilter;
      final searchMatch = q.isEmpty || o.id.toLowerCase().contains(q);
      final dateMatch = _matchesDateFilter(o.date);
      return statusMatch && storeMatch && paymentMatch && searchMatch && dateMatch;
    }).toList();
  }

  bool _matchesDateFilter(DateTime orderDate) {
    final now = DateTime.now();
    final d = DateTime(orderDate.year, orderDate.month, orderDate.day);
    final today = DateTime(now.year, now.month, now.day);
    if (_dateFilter == 'date_today') return d == today;
    if (_dateFilter == 'date_last_7_days') {
      return !d.isBefore(today.subtract(const Duration(days: 6))) && !d.isAfter(today);
    }
    if (_dateFilter == 'date_this_month') {
      return d.year == now.year && d.month == now.month;
    }
    return true;
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
      listenable: Listenable.merge([_ordersManager, _ratingsManager]),
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
                  _buildOrderSearch(),
                  const SizedBox(height: 10),
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
          backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.65),
          child: AppBackIconButton(
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

  Widget _buildOrderSearch() {
    return TextField(
      onChanged: (v) => setState(() => _orderSearch = v),
      style: GoogleFonts.cairo(color: Colors.white),
      decoration: InputDecoration(
        hintText: context.tr('search_order_id'),
        hintStyle: GoogleFonts.cairo(color: Colors.white38),
        prefixIcon: const Icon(Icons.search, color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1E5BB3).withOpacity(0.15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final storeValues = ['all_stores', ..._ordersManager.orders.map((o) => o.storeName).toSet()];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildCompactDropdown(
          value: _statusFilter,
          values: const ['status_all', 'status_pending', 'status_ready', 'status_delivered'],
          onChanged: (v) => setState(() => _statusFilter = v!),
        ),
        _buildCompactDropdown(
          value: _storeFilter,
          values: storeValues,
          onChanged: (v) => setState(() => _storeFilter = v!),
        ),
        _buildCompactDropdown(
          value: _paymentFilter,
          values: const ['all_payments', 'wallet'],
          onChanged: (v) => setState(() => _paymentFilter = v!),
        ),
        _buildCompactDropdown(
          value: _dateFilter,
          values: const ['all_dates', 'date_today', 'date_last_7_days', 'date_this_month'],
          onChanged: (v) => setState(() => _dateFilter = v!),
        ),
      ],
    );
  }

  Widget _buildCompactDropdown({
    required String value,
    required List<String> values,
    required void Function(String?) onChanged,
  }) {
    return Container(
      width: 165,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E5BB3).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF152a45),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
          style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
          items: values
              .map(
                (v) => DropdownMenuItem(
                  value: v,
                  child: Text(v.startsWith('store_') ? context.tr(v) : context.tr(v)),
                ),
              )
              .toList(),
          onChanged: onChanged,
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
          const SizedBox(height: 4),
          Text(
            '${context.tr('store_label')}: ${context.tr(order.storeName)}',
            style: GoogleFonts.cairo(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 2),
          Text(
            '${context.tr('payment_method_label')}: ${context.tr(order.paymentMethod)}',
            style: GoogleFonts.cairo(fontSize: 13, color: Colors.white54),
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
          if (order.status == 'status_delivered') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _ratingsManager.hasRatedStoreForOrder(order.id)
                        ? null
                        : () => _rateStore(order),
                    icon: const Icon(Icons.storefront_outlined, size: 18),
                    label: Text(
                      _ratingsManager.hasRatedStoreForOrder(order.id)
                          ? context.tr('store_rated_done')
                          : context.tr('rate_store'),
                      style: GoogleFonts.cairo(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _ratingsManager.hasRatedAllProductsForOrder(
                      order.id,
                      order.items.map((e) => e.product.name).toList(),
                    )
                        ? null
                        : () => _rateProducts(order),
                    icon: const Icon(Icons.star_border_rounded, size: 18),
                    label: Text(
                      _ratingsManager.hasRatedAllProductsForOrder(
                        order.id,
                        order.items.map((e) => e.product.name).toList(),
                      )
                          ? context.tr('products_rated_done')
                          : context.tr('rate_products'),
                      style: GoogleFonts.cairo(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _rateStore(Order order) async {
    final selected = await _showRatingDialog(context.tr('rate_store'));
    if (selected == null) return;
    _ratingsManager.submitStoreRating(
      orderId: order.id,
      storeKey: order.storeName,
      rating: selected,
    );
  }

  Future<void> _rateProducts(Order order) async {
    for (final item in order.items) {
      if (_ratingsManager.hasRatedProductForOrder(order.id, item.product.name)) continue;
      final selected = await _showRatingDialog(context.tr(item.product.name));
      if (selected == null) return;
      _ratingsManager.submitProductRating(
        orderId: order.id,
        productKey: item.product.name,
        rating: selected,
      );
    }
  }

  Future<double?> _showRatingDialog(String title) async {
    double value = 5;
    return showDialog<double>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setInner) => AlertDialog(
            backgroundColor: const Color(0xFF152a45),
            title: Text(title, style: GoogleFonts.cairo(color: Colors.white)),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                return IconButton(
                  onPressed: () => setInner(() => value = star.toDouble()),
                  icon: Icon(
                    value >= star ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                );
              }),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(context.tr('cancel'), style: GoogleFonts.cairo(color: Colors.white70)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, value),
                child: Text(context.tr('save_changes'), style: GoogleFonts.cairo()),
              ),
            ],
          ),
        );
      },
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
            onPressed: () => setState(() {
              _statusFilter = 'status_all';
              _storeFilter = 'all_stores';
              _paymentFilter = 'all_payments';
              _dateFilter = 'all_dates';
              _orderSearch = '';
            }),
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
