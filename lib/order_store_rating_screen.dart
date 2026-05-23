import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'l10n/app_strings.dart';
import 'models/order.dart';
import 'models/ratings_manager.dart';
import 'widgets/app_back_button.dart';

/// تقييم المتجر بالنجوم فقط.
class OrderStoreRatingScreen extends StatefulWidget {
  final Order order;

  const OrderStoreRatingScreen({super.key, required this.order});

  @override
  State<OrderStoreRatingScreen> createState() => _OrderStoreRatingScreenState();
}

class _OrderStoreRatingScreenState extends State<OrderStoreRatingScreen> {
  final RatingsManager _ratings = RatingsManager();
  double _stars = 0;

  @override
  Widget build(BuildContext context) {
    final storeLabel = context.tr(widget.order.storeName);

    return Scaffold(
      backgroundColor: const Color(0xFF121026),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  const AppBackIconButton(),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('order_rating_title'),
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _card(
                      child: Text(
                        AppStrings.format(context, 'order_rating_order_line', params: {
                          'id': widget.order.id,
                          'store': storeLabel,
                        }),
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.storefront_outlined, color: Color(0xFF3B82F6), size: 22),
                              const SizedBox(width: 8),
                              Text(
                                context.tr('store_rating_section'),
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppStrings.format(context, 'store_rating_prompt', params: {'store': storeLabel}),
                            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 15),
                          ),
                          const SizedBox(height: 20),
                          _starRow(_stars, (v) => setState(() => _stars = v)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _stars < 1
                      ? null
                      : () {
                          _ratings.submitStoreRating(
                            orderId: widget.order.id,
                            storeKey: widget.order.storeName,
                            rating: _stars,
                          );
                          Navigator.pop(context, true);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA855F7),
                    disabledBackgroundColor: Colors.white12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    context.tr('submit_rating'),
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }

  Widget _starRow(double value, ValueChanged<double> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final star = (i + 1).toDouble();
        return IconButton(
          onPressed: () => onChanged(star),
          icon: Icon(
            value >= star ? Icons.star_rounded : Icons.star_border_rounded,
            color: Colors.amber,
            size: 40,
          ),
        );
      }),
    );
  }
}
