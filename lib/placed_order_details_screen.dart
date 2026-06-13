import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'data/product_images.dart';
import 'l10n/app_strings.dart';
import 'models/cart_item.dart';
import 'models/order.dart';
import 'models/orders_manager.dart';
import 'services/api/api_exception.dart';
import 'widgets/app_back_button.dart';
import 'widgets/store_cover_image.dart';

/// تفاصيل طلب مُنشأ — GET /api/orders/{id} (OTP، المنتجات، الحالة).
class PlacedOrderDetailsScreen extends StatefulWidget {
  final Order order;

  const PlacedOrderDetailsScreen({super.key, required this.order});

  @override
  State<PlacedOrderDetailsScreen> createState() => _PlacedOrderDetailsScreenState();
}

class _PlacedOrderDetailsScreenState extends State<PlacedOrderDetailsScreen> {
  final OrdersManager _ordersManager = OrdersManager();

  late Order _order;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _refreshDetails();
  }

  Future<void> _refreshDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final fresh = await _ordersManager.loadOrderDetails(_order);
      if (!mounted) return;
      setState(() => _order = fresh);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _localizedOrRaw(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    final translated = context.tr(trimmed);
    return translated == trimmed ? trimmed : translated;
  }

  String _formatDate(DateTime d) {
    if (context.isRtl) {
      final day = d.day.toString().padLeft(2, '0');
      final month = AppStrings.of(context, 'month_${d.month}');
      return '$day $month ${d.year}';
    }
    final day = d.day.toString();
    final month = AppStrings.of(context, 'month_${d.month}');
    return '$month $day, ${d.year}';
  }

  String _lineImageUrl(CartItem line) {
    final remote = line.product.imageUrl.trim();
    if (remote.isNotEmpty) return remote;
    return ProductImages.forProductKey(line.product.name);
  }

  Future<void> _copyOtp(String otp) async {
    await Clipboard.setData(ClipboardData(text: otp));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('order_otp_copied'), style: GoogleFonts.cairo()),
        backgroundColor: const Color(0xFF22C55E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDelivered = _order.status == 'status_delivered';
    final otp = _order.otpCode?.trim() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF121026),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    context.tr('order_details_title'),
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AppBackIconButton(),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: IconButton(
                      onPressed: _loading ? null : () => _refreshDetails(),
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                      tooltip: context.tr('refresh'),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!, style: GoogleFonts.cairo(color: Colors.orangeAccent, fontSize: 13)),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${context.tr('order_hashtag')}#${_order.id}',
                                        style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    _statusChip(_order.status),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _infoRow(Icons.storefront_outlined, context.tr('store_label'), _localizedOrRaw(_order.storeName)),
                                _infoRow(Icons.calendar_today_outlined, context.tr('order_date_label'), _formatDate(_order.date)),
                                _infoRow(Icons.account_balance_wallet_outlined, context.tr('payment_method_label'), context.tr(_order.paymentMethod)),
                                if (_order.driverName != null && _order.driverName!.isNotEmpty)
                                  _infoRow(Icons.delivery_dining_outlined, context.tr('driver_label'), _order.driverName!),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  context.tr('order_otp_label'),
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isDelivered
                                      ? context.tr('order_otp_used')
                                      : context.tr('order_otp_hint'),
                                  style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13),
                                ),
                                const SizedBox(height: 16),
                                if (otp.isNotEmpty && !isDelivered)
                                  InkWell(
                                    onTap: () => _copyOtp(otp),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF121026),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFF3B82F6)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            otp,
                                            style: GoogleFonts.cairo(
                                              color: Colors.white,
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 8,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Icon(Icons.copy_rounded, color: Color(0xFF3B82F6), size: 20),
                                        ],
                                      ),
                                    ),
                                  )
                                else if (isDelivered)
                                  Text(
                                    context.tr('driver_confirmed_delivery'),
                                    style: GoogleFonts.cairo(color: Colors.greenAccent, fontSize: 14),
                                  )
                                else
                                  Text(
                                    context.tr('order_otp_pending'),
                                    style: GoogleFonts.cairo(color: Colors.white54, fontSize: 14),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.tr('order_items_label'),
                            style: GoogleFonts.cairo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          for (final item in _order.items) _itemCard(item),
                          const SizedBox(height: 16),
                          _card(
                            child: Column(
                              children: [
                                if (_order.deliveryFee > 0) ...[
                                  _totalRow(context.tr('cart_delivery_price'), _order.deliveryFee),
                                  const SizedBox(height: 8),
                                ],
                                _totalRow(context.tr('order_total_label'), _order.totalPrice, bold: true),
                              ],
                            ),
                          ),
                          if (!isDelivered) ...[
                            const SizedBox(height: 16),
                            Text(
                              context.tr('awaiting_driver_otp'),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(color: Colors.white54, fontSize: 13),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'status_ready':
        bg = Colors.green.withValues(alpha: 0.25);
        fg = Colors.lightGreenAccent;
      case 'status_delivered':
        bg = const Color(0xFF7C4DFF).withValues(alpha: 0.28);
        fg = const Color(0xFFD1B3FF);
      case 'status_cancelled':
        bg = Colors.red.withValues(alpha: 0.2);
        fg = Colors.redAccent;
      default:
        bg = const Color(0xFFE6B422).withValues(alpha: 0.25);
        fg = const Color(0xFFFFE082);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        context.tr(status),
        style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.white54),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.cairo(color: Colors.white54, fontSize: 12)),
                Text(value, style: GoogleFonts.cairo(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemCard(CartItem item) {
    final parts = <String>[];
    if (item.selectedColor.trim().isNotEmpty) parts.add(_localizedOrRaw(item.selectedColor));
    if (item.selectedSize.trim().isNotEmpty) parts.add(item.selectedSize);
    parts.add('${context.tr('quantity')}: ${item.quantity}');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: StoreCoverImage(
              imageUrl: _lineImageUrl(item),
              width: 64,
              height: 64,
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
                  style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(parts.join(' • '), style: GoogleFonts.cairo(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 6),
                Text(
                  '${item.totalPrice.toStringAsFixed(0)}${context.tr('currency_suffix')}',
                  style: GoogleFonts.cairo(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, double amount, {bool bold = false}) {
    return Row(
      children: [
        Expanded(child: Text(label, style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14))),
        Text(
          '${amount.toStringAsFixed(0)}${context.tr('currency_suffix')}',
          style: GoogleFonts.cairo(
            color: bold ? Colors.lightBlueAccent : Colors.white,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            fontSize: bold ? 18 : 14,
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }
}
