import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/trendy_theme_extension.dart';

/// مسارات شعار Trendy.
class TrendyAssets {
  TrendyAssets._();

  static const logoFull = 'assets/images/brand/trendy_logo_full.png';
  static const logoSplash = 'assets/images/brand/splash_screen_full.png';
}

/// الشعار الكامل — لشاشات الدخول والتسجيل.
class TrendyLogoHeader extends StatelessWidget {
  const TrendyLogoHeader({
    super.key,
    this.subtitle,
    this.logoHeight = 160,
  });

  final String? subtitle;
  final double logoHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          TrendyAssets.logoFull,
          height: logoHeight,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.authTextMuted,
            ),
          ),
        ],
      ],
    );
  }
}

/// شارة Trendy — الاسم في رؤوس الصفحات.
class TrendyBrandBadge extends StatelessWidget {
  const TrendyBrandBadge({
    super.key,
    this.textSize = 20,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.backgroundColor,
    this.borderRadius = 10,
  });

  final double textSize;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final t = context.trendy;
    final bg = backgroundColor ?? const Color(0xFFA855F7).withValues(alpha: 0.3);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        'Trendy',
        style: GoogleFonts.cairo(
          fontSize: textSize,
          fontWeight: FontWeight.bold,
          color: t.titleColor,
        ),
      ),
    );
  }
}
