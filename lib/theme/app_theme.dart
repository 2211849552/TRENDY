import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'trendy_theme_extension.dart';

class AppTheme {
  AppTheme._();

  static ThemeData dark({required bool isAr}) => _build(isAr: isAr, trendy: TrendyTheme.dark, brightness: Brightness.dark);

  static ThemeData light({required bool isAr}) => _build(isAr: isAr, trendy: TrendyTheme.light, brightness: Brightness.light);

  static ThemeData _build({
    required bool isAr,
    required TrendyTheme trendy,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    final base = isDark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);

    final scheme = (isDark ? ColorScheme.dark : ColorScheme.light)(
      primary: AppColors.primary,
      onPrimary: AppColors.textOnGradient,
      secondary: AppColors.secondary,
      onSecondary: AppColors.textOnGradient,
      surface: trendy.surfaceColor,
      onSurface: trendy.titleColor,
      error: AppColors.error,
      onError: AppColors.textOnGradient,
    ).copyWith(
      surfaceContainerHighest: isDark ? AppColors.card : const Color(0xFFF5F3FF),
      outline: trendy.cardBorder,
    );

    final textTheme = (isAr ? GoogleFonts.cairoTextTheme(base.textTheme) : GoogleFonts.interTextTheme(base.textTheme))
        .apply(bodyColor: trendy.titleColor, displayColor: trendy.titleColor);

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: trendy.pageBackground,
      canvasColor: trendy.pageBackground,
      dividerColor: trendy.dividerColor,
      extensions: [trendy],
      textTheme: textTheme.copyWith(
        bodyMedium: textTheme.bodyMedium?.copyWith(color: trendy.subtitleColor),
        bodySmall: textTheme.bodySmall?.copyWith(color: trendy.subtitleColor),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: trendy.pageBackground,
        foregroundColor: trendy.titleColor,
        iconTheme: IconThemeData(color: trendy.titleColor),
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: trendy.surfaceColor,
        elevation: isDark ? 0 : 1,
        shadowColor: isDark ? Colors.transparent : Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: trendy.cardBorder),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: trendy.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: trendy.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: trendy.inputFill,
        hintStyle: textTheme.bodyMedium?.copyWith(color: trendy.hintColor),
        labelStyle: textTheme.bodyMedium?.copyWith(color: trendy.titleColor),
        prefixIconColor: trendy.subtitleColor,
        suffixIconColor: trendy.subtitleColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: trendy.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnGradient,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return isDark ? Colors.white70 : Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return isDark ? Colors.white24 : const Color(0xFFE5E7EB);
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: trendy.navBarBackground,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: trendy.subtitleColor,
        type: BottomNavigationBarType.fixed,
        elevation: isDark ? 0 : 8,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: trendy.surfaceColor,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: trendy.titleColor),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.secondary),
    );
  }
}
