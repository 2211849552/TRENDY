import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../customer_reviews_screen.dart';
import '../l10n/app_strings.dart';

/// زر تقييمات وتعليقات الزبائن على المتجر — يعرض GET /api/stores/{id}/ratings.
class StoreCommentsButton extends StatelessWidget {
  final int storeId;
  final String storeTitle;
  final String imageUrl;
  final String? subtitle;

  const StoreCommentsButton({
    super.key,
    required this.storeId,
    required this.storeTitle,
    required this.imageUrl,
    this.subtitle,
  });

  void _open(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerReviewsScreen.store(
          storeId: storeId,
          title: storeTitle,
          imageUrl: imageUrl,
          subtitle: subtitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        onPressed: storeId > 0 ? () => _open(context) : null,
        icon: const Icon(Icons.rate_review_outlined, size: 18, color: Color(0xFF3B82F6)),
        label: Text(
          context.tr('store_comments'),
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
