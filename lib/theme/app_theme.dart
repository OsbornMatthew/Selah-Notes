import 'package:flutter/material.dart';

class AppColors {
  static const Color bgTop = Color(0xFF1A1408);
  static const Color bgBottom = Color(0xFF0A0907);
  static const Color background = Color(0xFF0D0B08);

  static const Color gold = Color(0xFFD4AF37);
  static const Color goldBright = Color(0xFFF1C84A);
  static const Color goldMuted = Color(0xFF8A7430);
  static const Color goldSoft = Color(0x33D4AF37);

  static const Color glassFill = Color(0x14FFFFFF);
  static const Color glassBorder = Color(0x33D4AF37);
  static const Color glassHighlight = Color(0x1AFFFFFF);

  static const Color textPrimary = Color(0xFFF5EFE0);
  static const Color textSecondary = Color(0xFFB8AD96);
  static const Color textFaint = Color(0xFF7A715F);

  static const Color divider = Color(0x1FD4AF37);
  static const Color danger = Color(0xFFE0788A);
}

class AppTheme {
  static ThemeData get darkGold {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.gold,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        secondary: AppColors.goldBright,
        surface: AppColors.background,
        error: AppColors.danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.gold,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          fontFamily: 'serif',
          letterSpacing: 0.3,
        ),
        iconTheme: IconThemeData(color: AppColors.gold),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
        fontFamily: 'sans-serif',
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.black,
        elevation: 8,
      ),
      iconTheme: const IconThemeData(color: AppColors.gold),
      dividerColor: AppColors.divider,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textFaint),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.bgTop,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
