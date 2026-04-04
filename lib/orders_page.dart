import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/orders_manager.dart';

class OrdersPage extends StatefulWidget {
  final VoidCallback onBrowseStores;

  const OrdersPage({super.key, required this.onBrowseStores});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final OrdersManager _ordersManager = OrdersManager();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ordersManager,
      builder: (context, _) {
        bool isEmpty = _ordersManager.count == 0;

        return Container(
          color: const Color(0xFF0A1931),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Header (Branding)
                _buildHeader(),
                const SizedBox(height: 32),
                
                // Content Title and Back Button
                _buildSubHeader(isEmpty),
                
                const SizedBox(height: 24),
                
                Expanded(
                  child: isEmpty ? _buildEmptyState() : _buildOrdersList(),
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
          color: const Color(0xFF1E5BB3).withValues(alpha: 0.3),
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
          'الطلبات (${_ordersManager.count})',
          style: GoogleFonts.cairo(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersList() {
    return ListView.builder(
      itemCount: _ordersManager.count,
      itemBuilder: (context, index) {
        final order = _ordersManager.orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(dynamic order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E5BB3).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الطلب #${order.id}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  order.status,
                  style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'التاريخ: ${order.date.day}/${order.date.month}/${order.date.year}',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            'المجموع: ${order.totalPrice} د.ل',
            style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
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
            color: Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.inventory_2_outlined,
            size: 100,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'لا توجد طلبات',
          style: GoogleFonts.cairo(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'لم تقم بأي طلبات بعد',
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
              'ابدأ التسوق',
              style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
