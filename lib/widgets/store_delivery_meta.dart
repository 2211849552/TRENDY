import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_strings.dart';
import '../theme/trendy_theme_extension.dart';

/// علامات صغيرة: التقييم، التوصيل، المسافة، نوع المتجر — بنفس صيغة التصنيفات.
class StoreDeliveryMeta extends StatelessWidget {
  const StoreDeliveryMeta({
    super.key,
    required this.rating,
    required this.deliveryFee,
    required this.distanceText,
    required this.isElectronic,
    this.compact = true,
  });

  final double rating;
  final double deliveryFee;
  final String distanceText;
  final bool isElectronic;
  /// `true` للبطاقات في الصفحة الرئيسية، `false` لرأس صفحة المتجر.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final trendy = context.trendy;
    final typeColor = isElectronic ? Colors.greenAccent : Colors.orangeAccent;
    final typeIcon = isElectronic ? Icons.smartphone_outlined : Icons.storefront_outlined;
    final typeLabel = isElectronic
        ? context.tr('store_type_electronic')
        : context.tr('store_type_physical');
    final deliveryLabel =
        '${deliveryFee.toStringAsFixed(0)}${context.tr('currency_suffix')}';
    final distanceLabel = distanceText == '--'
        ? '--'
        : '$distanceText${context.tr('km_suffix')}';

    final bgColor = compact
        ? trendy.cardFill.withValues(alpha: 0.35)
        : Colors.white.withValues(alpha: 0.05);
    final textColor = compact ? Colors.white70 : Colors.white70;
    final fontSize = compact ? 9.0 : 11.0;
    final iconSize = compact ? 10.0 : 12.0;
    final hPad = compact ? 6.0 : 10.0;
    final vPad = compact ? 3.0 : 4.0;

    return Wrap(
      spacing: compact ? 4 : 8,
      runSpacing: compact ? 4 : 8,
      alignment: WrapAlignment.end,
      children: [
        _MetaTag(
          icon: Icons.local_shipping_outlined,
          iconColor: const Color(0xFF3B82F6),
          label: deliveryLabel,
          textColor: compact ? trendy.titleColor : textColor,
          bgColor: bgColor,
          fontSize: fontSize,
          iconSize: iconSize,
          hPad: hPad,
          vPad: vPad,
        ),
        _MetaTag(
          icon: Icons.star,
          iconColor: Colors.amber,
          label: rating.toStringAsFixed(1),
          textColor: compact ? trendy.titleColor : textColor,
          bgColor: bgColor,
          fontSize: fontSize,
          iconSize: iconSize,
          hPad: hPad,
          vPad: vPad,
        ),
        _MetaTag(
          icon: Icons.location_on_outlined,
          iconColor: const Color(0xFF3B82F6),
          label: distanceLabel,
          textColor: textColor,
          bgColor: bgColor,
          fontSize: fontSize,
          iconSize: iconSize,
          hPad: hPad,
          vPad: vPad,
        ),
        _MetaTag(
          icon: typeIcon,
          iconColor: typeColor,
          label: typeLabel,
          textColor: typeColor,
          bgColor: bgColor,
          fontSize: fontSize,
          iconSize: iconSize,
          hPad: hPad,
          vPad: vPad,
        ),
      ],
    );
  }
}

class _MetaTag extends StatelessWidget {
  const _MetaTag({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.textColor,
    required this.bgColor,
    required this.fontSize,
    required this.iconSize,
    required this.hPad,
    required this.vPad,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final Color textColor;
  final Color bgColor;
  final double fontSize;
  final double iconSize;
  final double hPad;
  final double vPad;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: iconSize),
          SizedBox(width: fontSize > 9 ? 4 : 3),
          Text(
            label,
            style: GoogleFonts.cairo(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
