import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../checkout/checkout_sheets.dart';
import '../data/store_catalog.dart';
import '../l10n/app_strings.dart';
import '../locale/app_locale.dart';
import '../models/addresses_manager.dart';
import '../models/cart_item.dart';
import '../models/cart_manager.dart';
import '../models/order.dart';
import '../models/orders_manager.dart';
import '../models/wallet_manager.dart';
import '../theme/app_colors.dart';
import '../theme/trendy_theme_extension.dart';
import '../widgets/gradient_button.dart';
import '../widgets/schematic_map_tiles.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({
    super.key,
    required this.storeKey,
    required this.items,
    required this.productsTotal,
    required this.deliveryFee,
    required this.onOrderPlaced,
  });

  final String storeKey;
  final List<CartItem> items;
  final double productsTotal;
  final double deliveryFee;
  final VoidCallback onOrderPlaced;

  /// تفاصيل الطلب كلوحة منبثقة فوق السلة — وليس شاشة كاملة.
  static Future<void> show(
    BuildContext context, {
    required String storeKey,
    required List<CartItem> items,
    required double productsTotal,
    required double deliveryFee,
    required VoidCallback onOrderPlaced,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (ctx) => OrderDetailsScreen(
        storeKey: storeKey,
        items: items,
        productsTotal: productsTotal,
        deliveryFee: deliveryFee,
        onOrderPlaced: onOrderPlaced,
      ),
    );
  }

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final AddressesManager _addresses = AddressesManager();
  final TextEditingController _notesController = TextEditingController();
  final MapController _mapController = MapController();

  String? _paymentMethod;
  bool _orderSummaryExpanded = false;
  bool _notesExpanded = false;

  double get _grandTotal => widget.productsTotal + widget.deliveryFee;

  int get _itemCount => widget.items.fold(0, (sum, i) => sum + i.quantity);

  @override
  void dispose() {
    _notesController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _pickAddress() => showAddressPickerSheet(context);

  Future<void> _pickPayment() async {
    final picked = await showPaymentPickerSheet(context, initial: _paymentMethod);
    if (picked != null && mounted) {
      setState(() => _paymentMethod = picked);
    }
  }

  Future<void> _confirmOrder() async {
    if (_paymentMethod == null) {
      final picked = await showPaymentPickerSheet(context);
      if (picked == null || !mounted) return;
      setState(() => _paymentMethod = picked);
    }
    await _placeOrder();
  }

  Future<void> _placeOrder() async {
    if (_paymentMethod == null) return;

    final orderId = DateTime.now().millisecondsSinceEpoch.toString();
    final total = _grandTotal;

    if (_paymentMethod == 'payment_wallet') {
      if (!WalletManager().payOrderFromWallet(orderId: orderId, amount: total)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('wallet_insufficient'), style: GoogleFonts.cairo()),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    final orderItems = widget.items
        .map(
          (e) => CartItem(
            product: e.product,
            selectedColor: e.selectedColor,
            selectedSize: e.selectedSize,
            quantity: e.quantity,
          ),
        )
        .toList();

    OrdersManager().addOrder(
      Order(
        id: orderId,
        date: DateTime.now(),
        items: orderItems,
        totalPrice: total,
        status: 'status_pending',
        storeName: widget.storeKey,
        paymentMethod: _paymentMethod!,
      ),
    );

    for (final item in widget.items) {
      CartManager().removeFromCart(item);
    }

    widget.onOrderPlaced();

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(context.tr('order_confirmed'), style: GoogleFonts.cairo()),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  String _paymentLabel(BuildContext context) {
    if (_paymentMethod == null) return context.tr('select_payment_method');
    return context.tr(_paymentMethod!);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.trendy;
    final address = _addresses.selected;
    final store = StoreCatalog.findByKey(widget.storeKey);
    final storeLabel = store != null ? context.tr(store['name'] as String) : widget.storeKey;
    final maxHeight = MediaQuery.of(context).size.height * 0.88;

    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.06),
      child: Directionality(
        textDirection: context.isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: ListenableBuilder(
          listenable: Listenable.merge([_addresses, AppLocale.instance]),
          builder: (context, _) {
            return Container(
              constraints: BoxConstraints(maxHeight: maxHeight),
              decoration: BoxDecoration(
                color: t.surfaceColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSheetHandle(),
                  _buildHeader(t),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (address != null) _buildMiniMap(address),
                          const SizedBox(height: 10),
                          _buildTappableCard(
                            icon: Icons.location_on_outlined,
                            title: address?.label ?? context.tr('select_your_address'),
                            onTap: _pickAddress,
                          ),
                          const SizedBox(height: 14),
                          _SectionLabel(context.tr('order_notes_label')),
                          _buildNotesCard(t),
                          const SizedBox(height: 14),
                          _SectionLabel(context.tr('order_summary_section')),
                          _buildOrderSummaryCard(t, storeLabel),
                          const SizedBox(height: 14),
                          _SectionLabel(context.tr('payment_method_label')),
                          _buildTappableCard(
                            icon: Icons.payments_outlined,
                            title: _paymentLabel(context),
                            muted: _paymentMethod == null,
                            onTap: _pickPayment,
                          ),
                          const SizedBox(height: 14),
                          _SectionLabel(context.tr('invoice_title')),
                          _buildInvoiceCard(t),
                        ],
                      ),
                    ),
                  ),
                  _buildConfirmBar(t),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSheetHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(TrendyTheme t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded, color: t.subtitleColor, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Expanded(
            child: Text(
              context.tr('order_details_title'),
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                color: t.titleColor,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildMiniMap(SavedAddress address) {
    final point = LatLng(address.lat, address.lng);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 100,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: point,
            initialZoom: 14,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
          ),
          children: [
            TileLayer(
              urlTemplate: '',
              tileProvider: SchematicTileProvider(isLight: false),
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 30,
                  height: 30,
                  child: const Icon(Icons.location_on, color: Colors.redAccent, size: 30),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTappableCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool muted = false,
  }) {
    final t = context.trendy;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: t.cardFill.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.cardBorder),
          ),
          child: Row(
            children: [
              Icon(Icons.keyboard_arrow_down_rounded, color: t.subtitleColor, size: 20),
              const Spacer(),
              Expanded(
                flex: 3,
                child: Text(
                  title,
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    color: muted ? t.subtitleColor : t.titleColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: AppColors.secondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesCard(TrendyTheme t) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _notesExpanded = !_notesExpanded),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: t.cardFill.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    _notesExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: t.subtitleColor,
                    size: 20,
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      _notesController.text.isEmpty
                          ? context.tr('order_notes_hint')
                          : _notesController.text,
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        color: _notesController.text.isEmpty ? t.subtitleColor : t.titleColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.edit_outlined, color: t.subtitleColor, size: 18),
                ],
              ),
              if (_notesExpanded) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  style: GoogleFonts.cairo(color: t.titleColor, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: context.tr('order_notes_hint'),
                    hintStyle: GoogleFonts.cairo(color: t.subtitleColor, fontSize: 13),
                    filled: true,
                    fillColor: t.pageBackground.withValues(alpha: 0.5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: t.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: t.cardBorder),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard(TrendyTheme t, String storeLabel) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _orderSummaryExpanded = !_orderSummaryExpanded),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: t.cardFill.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    _orderSummaryExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: t.subtitleColor,
                    size: 20,
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        storeLabel,
                        style: GoogleFonts.cairo(
                          color: t.titleColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        AppStrings.format(
                          context,
                          'order_items_count',
                          params: {'count': '$_itemCount'},
                        ),
                        style: GoogleFonts.cairo(color: t.subtitleColor, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.storefront_outlined, color: AppColors.secondary, size: 20),
                ],
              ),
              if (_orderSummaryExpanded) ...[
                const Divider(color: Colors.white12, height: 20),
                ...widget.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Text(
                          '×${item.quantity}',
                          style: GoogleFonts.cairo(color: t.subtitleColor, fontSize: 12),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            context.tr(item.product.name),
                            textAlign: TextAlign.end,
                            style: GoogleFonts.cairo(color: t.titleColor, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(TrendyTheme t) {
    final suffix = context.tr('currency_suffix');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.cardFill.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.cardBorder),
      ),
      child: Column(
        children: [
          _invoiceRow(context.tr('cart_items_price'), '${widget.productsTotal.toStringAsFixed(0)}$suffix'),
          const SizedBox(height: 10),
          _invoiceRow(context.tr('cart_delivery_price'), '${widget.deliveryFee.toStringAsFixed(0)}$suffix'),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  context.tr('free_label'),
                  style: GoogleFonts.cairo(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                context.tr('service_fee'),
                style: GoogleFonts.cairo(color: t.subtitleColor, fontSize: 13),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Colors.white12, height: 1),
          ),
          _invoiceRow(
            context.tr('cart_total'),
            '${_grandTotal.toStringAsFixed(0)}$suffix',
            valueBold: true,
          ),
        ],
      ),
    );
  }

  Widget _invoiceRow(String label, String value, {bool valueBold = false}) {
    final t = context.trendy;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          value,
          style: GoogleFonts.cairo(
            color: t.titleColor,
            fontSize: valueBold ? 16 : 14,
            fontWeight: valueBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.cairo(
            color: valueBold ? t.titleColor : t.subtitleColor,
            fontSize: valueBold ? 14 : 13,
            fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmBar(TrendyTheme t) {
    final suffix = context.tr('currency_suffix');
    final totalText = '${_grandTotal.toStringAsFixed(0)}$suffix';
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(14, 10, 14, 12 + bottomPad),
      decoration: BoxDecoration(
        color: t.surfaceColor,
        border: Border(top: BorderSide(color: t.cardBorder)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: GradientButton(
          onPressed: _confirmOrder,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Text(
                totalText,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Text(
                  context.tr('confirm_order'),
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
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        textAlign: TextAlign.end,
        style: GoogleFonts.cairo(
          color: context.trendy.titleColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
