import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'data/product_images.dart';
import 'models/cart_item.dart';
import 'models/cart_manager.dart';
import 'models/order.dart';
import 'models/orders_manager.dart';
import 'models/ratings_manager.dart';
import 'services/api/api_exception.dart';
import 'l10n/app_strings.dart';
import 'theme/app_theme_mode.dart';
import 'theme/trendy_theme_extension.dart';
import 'order_rating_screen.dart';
import 'widgets/app_back_button.dart';
import 'widgets/store_cover_image.dart';
import 'widgets/gradient_button.dart';
import 'widgets/trendy_brand.dart';

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
  String _orderSearch = '';
  String? _actionOrderId;

  @override
  void initState() {
    super.initState();
    _ordersManager.syncFromApi();
  }

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
      final statusMatch = _matchesStatusFilter(o.status);
      final searchMatch = q.isEmpty || o.id.toLowerCase().contains(q);
      return statusMatch && searchMatch;
    }).toList();
  }

  bool _matchesStatusFilter(String orderStatus) {
    if (_statusFilter == 'status_all') return true;
    if (_statusFilter == 'status_completed') return orderStatus == 'status_delivered';
    if (_statusFilter == 'status_cancelled') return orderStatus == 'status_cancelled';
    return orderStatus == _statusFilter;
  }

  Color _statusBackground(String status) {
    switch (status) {
      case 'status_pending':
        return const Color(0xFFE6B422).withOpacity(0.25);
      case 'status_ready':
        return Colors.green.withOpacity(0.25);
      case 'status_delivered':
        return const Color(0xFF7C4DFF).withOpacity(0.28);
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
        return const Color(0xFFD1B3FF);
      default:
        return Colors.white70;
    }
  }

  Future<void> _simulateReady(Order order) async {
    if (order.status != 'status_pending') return;
    setState(() => _actionOrderId = order.id);
    _ordersManager.simulateReadyForPickup(order.id);
    if (mounted) setState(() => _actionOrderId = null);
  }

  Future<void> _confirmDelivery(Order order) async {
    setState(() => _actionOrderId = order.id);
    try {
      await _ordersManager.confirmDelivery(order);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message, style: GoogleFonts.cairo()),
          backgroundColor: Colors.redAccent.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _actionOrderId = null);
    }
  }

  void _reorder(Order order) {
    try {
      for (final line in order.items) {
        _cartManager.addToCart(
          line.product,
          color: line.selectedColor.isNotEmpty ? line.selectedColor : 'أسود',
          size: line.selectedSize.isNotEmpty ? line.selectedSize : 'M',
          quantity: line.quantity,
          variantId: line.variantId,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('added_to_cart'), style: GoogleFonts.cairo()),
          backgroundColor: const Color(0xFFA855F7),
        ),
      );
    } on CartSingleStoreException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('cart_single_store_error'),
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.redAccent.shade700,
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
      listenable: Listenable.merge([_ordersManager, _ratingsManager, AppThemeMode.instance]),
      builder: (context, _) {
        final isEmpty = _ordersManager.count == 0;
        final list = _visibleOrders;

        return Container(
          color: context.trendy.pageBackground,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Directionality(
            textDirection: context.isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 32),
                _buildSubHeader(isEmpty),
                const SizedBox(height: 16),
                Expanded(
                  child: isEmpty
                      ? _buildEmptyState()
                      : list.isEmpty
                          ? _buildNoMatchesState()
                          : _buildScrollableOrders(list),
                ),
              ],
            ),
          ),
        );






      },
    );
  }

  Widget _buildHeader() {
    return const Center(
      child: TrendyBrandBadge(
        textSize: 24,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        borderRadius: 12,
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
                color: context.trendy.titleColor,
              ),
            ),
            if (!isEmpty)
              Text(
                '${_ordersManager.count} ${context.tr('orders_count')}',
                style: GoogleFonts.cairo(fontSize: 14, color: context.trendy.subtitleColor),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterRow() {
    return Row(
      children: [
        SizedBox(
          width: 148,
          child: _buildStatusDropdown(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            onChanged: (v) => setState(() => _orderSearch = v),
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: context.tr('search_order_id'),
              hintStyle: GoogleFonts.cairo(color: Colors.white38, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 22),
              filled: true,
              fillColor: const Color(0xFF1E1B4B),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    const values = [
      'status_all',
      'status_pending',
      'status_completed',
      'status_cancelled',
      'status_ready',
      'status_delivered',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _statusFilter,
          isExpanded: true,
          dropdownColor: const Color(0xFF1E1B4B),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 22),
          style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
          items: values
              .map((v) => DropdownMenuItem(value: v, child: Text(context.tr(v))))
              .toList(),
          onChanged: (v) => setState(() => _statusFilter = v!),
        ),
      ),
    );
  }

  Widget _buildScrollableOrders(List<Order> orders) {
    return RefreshIndicator(
      onRefresh: _ordersManager.syncFromApi,
      color: const Color(0xFF3B82F6),
      child: CustomScrollView(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _PinnedSearchBarDelegate(
            child: Container(
              color: const Color(0xFF121026),
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSearchAndFilterRow(),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildOrderCard(orders[index]),
            childCount: orders.length,
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    ),
    );
  }

  String _localizedOrRaw(BuildContext context, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    final translated = context.tr(trimmed);
    return translated == trimmed ? trimmed : translated;
  }

  String _lineDetailText(BuildContext context, CartItem line) {
    final parts = <String>[];
    if (line.selectedColor.trim().isNotEmpty) {
      parts.add(_localizedOrRaw(context, line.selectedColor));
    }
    if (line.selectedSize.trim().isNotEmpty) {
      parts.add(line.selectedSize);
    }
    parts.add('${context.tr('quantity')}: ${line.quantity}');
    return parts.join(' • ');
  }

  String _lineImageUrl(CartItem line) {
    final remote = line.product.imageUrl.trim();
    if (remote.isNotEmpty) return remote;
    return ProductImages.forProductKey(line.product.name);
  }

  Widget _buildOrderLine(CartItem line) {
    final detail = _lineDetailText(context, line);
    final imageUrl = _lineImageUrl(line);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: StoreCoverImage(
              imageUrl: imageUrl,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _localizedOrRaw(context, line.product.name),
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: GoogleFonts.cairo(fontSize: 13, color: Colors.white54),
                ),
                const SizedBox(height: 8),
                Text(
                  '${line.totalPrice.toStringAsFixed(0)}${context.tr('currency_suffix')}',
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.lightBlueAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final productKeys = order.items.map((e) => e.product.name).toList();
    final fullyRated = _ratingsManager.isOrderFullyRated(order.id, productKeys);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusBackground(order.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  context.tr(order.status),
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusForeground(order.status),
                  ),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${context.tr('order_hashtag')}#${order.id}',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatDate(context, order.date),
                        style: GoogleFonts.cairo(fontSize: 12, color: Colors.white54),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.account_balance_wallet_outlined, size: 14, color: Colors.white54),
                      const SizedBox(width: 4),
                      Text(
                        context.tr(order.paymentMethod),
                        style: GoogleFonts.cairo(fontSize: 12, color: Colors.white54),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          for (final item in order.items) _buildOrderLine(item),
          const SizedBox(height: 14),
          Row(
            children: [
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    context.tr('order_total_label'),
                    style: GoogleFonts.cairo(fontSize: 13, color: Colors.white54),
                  ),
                  Text(
                    '${order.totalPrice.toStringAsFixed(0)}${context.tr('currency_suffix')}',
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.lightBlueAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildOrderActionRow(order, fullyRated),
        ],
      ),
    );
  }

  Widget _buildOrderActionRow(Order order, bool fullyRated) {
    final loading = _actionOrderId == order.id;
    final isDelivered = order.status == 'status_delivered';
    final isReady = order.status == 'status_ready';
    final isPending = order.status == 'status_pending';

    if (isDelivered) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: fullyRated ? null : () => _openRating(order),
          icon: Icon(
            fullyRated ? Icons.check_rounded : Icons.star_rounded,
            size: 20,
          ),
          label: Text(
            fullyRated ? context.tr('order_rated_done') : context.tr('rate_order'),
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: fullyRated ? Colors.white12 : const Color(0xFFE6B422),
            foregroundColor: fullyRated ? Colors.white54 : const Color(0xFF121026),
            disabledBackgroundColor: Colors.white12,
            disabledForegroundColor: Colors.white54,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: loading
                ? null
                : isPending
                    ? () => _simulateReady(order)
                    : isReady
                        ? () => _confirmDelivery(order)
                        : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isReady ? Colors.green : const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.white10,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    isPending
                        ? context.tr('ready_for_pickup_btn')
                        : context.tr('order_delivered_label'),
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          onPressed: () => _reorder(order),
          icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
          tooltip: context.tr('reorder'),
        ),
      ],
    );
  }

  Order _latestOrder(Order order) {
    for (final candidate in _ordersManager.orders) {
      if (candidate.id == order.id) return candidate;
      if (order.apiId != null && candidate.apiId == order.apiId) return candidate;
    }
    return order;
  }

  Future<void> _openRating(Order order) async {
    final latest = _latestOrder(order);
    final done = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => Directionality(
          textDirection: context.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: OrderRatingScreen(order: latest),
        ),
      ),
    );
    if (done == true && mounted) setState(() {});
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
              _orderSearch = '';
            }),
            child: Text(context.tr('view_all_orders'), style: GoogleFonts.cairo(color: const Color(0xFF3B82F6))),
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
        Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: t.cardFill,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.inventory_2_outlined,
            size: 100,
            color: t.subtitleColor.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          context.tr('orders_empty'),
          style: GoogleFonts.cairo(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: t.titleColor,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          context.tr('orders_empty_sub'),
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 16,
            color: t.subtitleColor,
          ),
        ),
        const SizedBox(height: 40),
        GradientButton(
          onPressed: widget.onBrowseStores,
          label: context.tr('start_shopping'),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        ),
      ],
    );
  }
}

class _PinnedSearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _PinnedSearchBarDelegate({required this.child});

  @override
  double get minExtent => 60;

  @override
  double get maxExtent => 60;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _PinnedSearchBarDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
