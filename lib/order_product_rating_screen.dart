import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'l10n/app_strings.dart';
import 'models/cart_item.dart';
import 'models/order.dart';
import 'models/ratings_manager.dart';
import 'widgets/app_back_button.dart';
import 'widgets/store_cover_image.dart';

/// تقييم المنتج: نجوم + صور اختيارية + تعليق اختياري.
class OrderProductRatingScreen extends StatefulWidget {
  final Order order;

  const OrderProductRatingScreen({super.key, required this.order});

  @override
  State<OrderProductRatingScreen> createState() => _OrderProductRatingScreenState();
}

class _OrderProductRatingScreenState extends State<OrderProductRatingScreen> {
  final RatingsManager _ratings = RatingsManager();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _commentController = TextEditingController();

  late int _index;
  late List<CartItem> _pending;
  double _stars = 0;
  final List<String> _imagePaths = [];

  @override
  void initState() {
    super.initState();
    _pending = widget.order.items
        .where((e) => !_ratings.hasRatedProductForOrder(widget.order.id, e.product.name))
        .toList();
    _index = 0;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  CartItem get _item => _pending[_index];

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;
    setState(() {
      _imagePaths.addAll(files.map((f) => f.path));
    });
  }

  void _submitCurrent() {
    if (_stars < 1) return;
    _ratings.submitProductRating(
      orderId: widget.order.id,
      productKey: _item.product.name,
      rating: _stars,
      comment: _commentController.text,
      imagePaths: _imagePaths,
    );
    if (_index + 1 >= _pending.length) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _index++;
      _stars = 0;
      _imagePaths.clear();
      _commentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_pending.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF121026),
        body: Center(
          child: Text(
            context.tr('products_rated_done'),
            style: GoogleFonts.cairo(color: Colors.white70),
          ),
        ),
      );
    }

    final p = _item.product;
    final progress = '${_index + 1} / ${_pending.length}';

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
                  Expanded(
                    child: Text(
                      context.tr('product_rating_section'),
                      style: GoogleFonts.cairo(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    progress,
                    style: GoogleFonts.cairo(color: Colors.white54, fontSize: 14),
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
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: StoreCoverImage(
                              imageUrl: p.imageUrl,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr(p.name),
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${context.tr(_item.selectedColor)} · ${_item.selectedSize}',
                                  style: GoogleFonts.cairo(color: Colors.white54, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _starRow(_stars, (v) => setState(() => _stars = v)),
                          const SizedBox(height: 24),
                          Text(
                            context.tr('rating_attach_photos'),
                            style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _pickImages,
                            icon: const Icon(Icons.add_photo_alternate_outlined),
                            label: Text(context.tr('rating_choose_photos'), style: GoogleFonts.cairo()),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF3B82F6),
                              side: const BorderSide(color: Color(0xFF3B82F6)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.format(context, 'rating_photos_count', params: {
                              'count': _imagePaths.length.toString(),
                            }),
                            style: GoogleFonts.cairo(color: Colors.white54, fontSize: 13),
                          ),
                          if (_imagePaths.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 72,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _imagePaths.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (_, i) {
                                  return Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          File(_imagePaths[i]),
                                          width: 72,
                                          height: 72,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 2,
                                        left: 2,
                                        child: GestureDetector(
                                          onTap: () => setState(() => _imagePaths.removeAt(i)),
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Text(
                            context.tr('rating_extra_notes'),
                            style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _commentController,
                            maxLines: 4,
                            style: GoogleFonts.cairo(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: context.tr('rating_comment_hint'),
                              hintStyle: GoogleFonts.cairo(color: Colors.white30),
                              filled: true,
                              fillColor: const Color(0xFF121026),
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
                  onPressed: _stars < 1 ? null : _submitCurrent,
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
