import 'package:flutter/material.dart';

import 'app_colors.dart';

/// ألوان دلالية تتغير بين الوضع الداكن والفاتح.
@immutable
class TrendyTheme extends ThemeExtension<TrendyTheme> {
  final Color pageBackground;
  final Color surfaceColor;
  final Color cardFill;
  final Color cardBorder;
  final Color titleColor;
  final Color subtitleColor;
  final Color hintColor;
  final Color dividerColor;
  final Color inputFill;
  final Color navBarBackground;

  const TrendyTheme({
    required this.pageBackground,
    required this.surfaceColor,
    required this.cardFill,
    required this.cardBorder,
    required this.titleColor,
    required this.subtitleColor,
    required this.hintColor,
    required this.dividerColor,
    required this.inputFill,
    required this.navBarBackground,
  });

  static const dark = TrendyTheme(
    pageBackground: AppColors.background,
    surfaceColor: AppColors.surface,
    cardFill: Color(0x1AA855F7),
    cardBorder: Color(0x1AFFFFFF),
    titleColor: Colors.white,
    subtitleColor: Color(0xFF94A3B8),
    hintColor: Color(0x61FFFFFF),
    dividerColor: Color(0x1AFFFFFF),
    inputFill: Color(0x8C252347),
    navBarBackground: AppColors.background,
  );

  static const light = TrendyTheme(
    pageBackground: Color(0xFFF3F4F8),
    surfaceColor: Colors.white,
    cardFill: Color(0xFFF5F3FF),
    cardBorder: Color(0xFFE5E7EB),
    titleColor: Color(0xFF111827),
    subtitleColor: Color(0xFF64748B),
    hintColor: Color(0xFF94A3B8),
    dividerColor: Color(0xFFE5E7EB),
    inputFill: Color(0xFFF9FAFB),
    navBarBackground: Colors.white,
  );

  @override
  TrendyTheme copyWith({
    Color? pageBackground,
    Color? surfaceColor,
    Color? cardFill,
    Color? cardBorder,
    Color? titleColor,
    Color? subtitleColor,
    Color? hintColor,
    Color? dividerColor,
    Color? inputFill,
    Color? navBarBackground,
  }) {
    return TrendyTheme(
      pageBackground: pageBackground ?? this.pageBackground,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      cardFill: cardFill ?? this.cardFill,
      cardBorder: cardBorder ?? this.cardBorder,
      titleColor: titleColor ?? this.titleColor,
      subtitleColor: subtitleColor ?? this.subtitleColor,
      hintColor: hintColor ?? this.hintColor,
      dividerColor: dividerColor ?? this.dividerColor,
      inputFill: inputFill ?? this.inputFill,
      navBarBackground: navBarBackground ?? this.navBarBackground,
    );
  }

  @override
  TrendyTheme lerp(ThemeExtension<TrendyTheme>? other, double t) {
    if (other is! TrendyTheme) return this;
    return TrendyTheme(
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t)!,
      cardFill: Color.lerp(cardFill, other.cardFill, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      titleColor: Color.lerp(titleColor, other.titleColor, t)!,
      subtitleColor: Color.lerp(subtitleColor, other.subtitleColor, t)!,
      hintColor: Color.lerp(hintColor, other.hintColor, t)!,
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      navBarBackground: Color.lerp(navBarBackground, other.navBarBackground, t)!,
    );
  }
}

extension TrendyThemeContext on BuildContext {
  TrendyTheme get trendy => Theme.of(this).extension<TrendyTheme>() ?? TrendyTheme.dark;
}
