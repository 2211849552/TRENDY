import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// زر بخلفية تدرج بنفسجي → أزرق (مثل لوحة التحكم).
class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? label;
  final Widget? child;
  final EdgeInsetsGeometry padding;

  const GradientButton({
    super.key,
    required this.onPressed,
    this.label,
    this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  }) : assert(label != null || child != null);

  @override
  Widget build(BuildContext context) {
    final content = child ??
        Text(
          label!,
          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: padding,
            child: DefaultTextStyle(
              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
