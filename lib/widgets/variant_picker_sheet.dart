import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_strings.dart';
import '../models/product_variant.dart';

/// اختيار تنوع (لون/مقاس) قبل نقل المنتج من المفضلة للسلة.
class VariantPickerSheet extends StatelessWidget {
  const VariantPickerSheet({
    super.key,
    required this.productName,
    required this.variants,
  });

  final String productName;
  final List<ProductVariantOption> variants;

  static Future<ProductVariantOption?> show(
    BuildContext context, {
    required String productName,
    required List<ProductVariantOption> variants,
  }) {
    final available = variants.where((v) => v.stock > 0).toList();
    if (available.isEmpty) return Future.value(null);
    if (available.length == 1) return Future.value(available.first);

    return showModalBottomSheet<ProductVariantOption>(
      context: context,
      backgroundColor: const Color(0xFF1E1B4B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => VariantPickerSheet(productName: productName, variants: available),
    );
  }

  String _variantLabel(BuildContext context, ProductVariantOption variant) {
    final parts = <String>[];
    final color = variant.colorValue;
    final size = variant.sizeValue;
    if (color != null && color.isNotEmpty) parts.add(context.tr(color));
    if (size != null && size.isNotEmpty) parts.add(size);
    if (parts.isEmpty) return '#${variant.id}';
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr(productName),
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              context.tr('select_variant_for_cart'),
              style: GoogleFonts.cairo(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ...variants.map(
              (variant) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  tileColor: Colors.white.withValues(alpha: 0.06),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  title: Text(
                    _variantLabel(context, variant),
                    style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    AppStrings.format(context, 'variant_stock_label', params: {
                      'count': '${variant.stock}',
                    }),
                    style: GoogleFonts.cairo(color: const Color(0xFF3B82F6), fontSize: 12),
                  ),
                  trailing: Text(
                    '${variant.price}${context.tr('currency_suffix')}',
                    style: GoogleFonts.cairo(color: Colors.white70),
                  ),
                  onTap: () => Navigator.pop(context, variant),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
