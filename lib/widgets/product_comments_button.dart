import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_strings.dart';
import '../customer_reviews_screen.dart';
import '../models/product.dart';

/// زر التعليقات تحت وصف المنتج — يفتح تقييمات وصور الزبائن.
class ProductCommentsButton extends StatelessWidget {
  final Product product;
  final String? variantLabel;

  const ProductCommentsButton({
    super.key,
    required this.product,
    this.variantLabel,
  });

  void _open(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerReviewsScreen.product(
          product: product,
          variantLabel: variantLabel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        onPressed: () => _open(context),
        icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF3B82F6)),
        label: Text(
          context.tr('product_comments'),
          style: GoogleFonts.cairo(
            color: const Color(0xFF3B82F6),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
