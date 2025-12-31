import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  // Brand Colors - Strict
  static const Color primaryRed = Color(0xFFE41D30);
  static const Color navyBlue = Color(0xFF020381);
  static const Color white = Color(0xFFFFFFFF);
  static const Color ebonyClay = Color(0xFF252638);

  // Derived/Functional Colors
  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFFF3B30); // iOS System Red
  static const Color warning = Color(0xFFFFCC00); // iOS System Yellow

  // Text Colors
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF3C3C43); // iOS Label Secondary
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textLightSecondary = Color(
    0xEBEBF599,
  ); // iOS Dark label secondary

  // Mesh/System Colors (Restored for build compatibility)
  static const Color meshGreen = Color(0xFF00E676);
  static const Color nostrPurple = Color(0xFF9D4EDD);
}

class AppTheme {
  // Telegram/iOS-like corner radius
  static const double bubbleRadius = 18.0;
  static const double cardRadius = 16.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primaryRed,
      scaffoldBackgroundColor: AppColors.white,

      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryRed,
        secondary: AppColors.navyBlue,
        surface: AppColors.white,
        onSurface: AppColors.ebonyClay,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),

      appBarTheme: AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: AppColors.ebonyClay,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppColors.ebonyClay),
      ),

      textTheme: TextTheme(
        // Headers
        displayLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.ebonyClay,
        ),
        displayMedium: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.ebonyClay,
        ),

        // Body
        bodyLarge: const TextStyle(
          fontSize: 16,
          height: 1.5,
          color: AppColors.ebonyClay,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: AppColors.navyBlue.withValues(alpha: 0.8),
        ),

        // Small/Caption
        bodySmall: TextStyle(
          fontSize: 12,
          color: AppColors.navyBlue.withValues(alpha: 0.6),
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: AppColors.navyBlue.withValues(alpha: 0.08)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF2F2F7), // iOS system fill
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5),
        ),
        hintStyle: TextStyle(color: AppColors.navyBlue.withValues(alpha: 0.4)),
      ),

      iconTheme: const IconThemeData(color: AppColors.navyBlue),

      dividerTheme: DividerThemeData(
        color: AppColors.navyBlue.withValues(alpha: 0.1),
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryRed,
      scaffoldBackgroundColor: AppColors.ebonyClay, // Strict Ebony Clay

      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryRed,
        secondary: AppColors.navyBlue,
        surface: AppColors.ebonyClay,
        onSurface: AppColors.white,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),

      appBarTheme: AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: AppColors.ebonyClay,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: AppColors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),

      textTheme: TextTheme(
        displayLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
        displayMedium: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          height: 1.5,
          color: AppColors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: AppColors.white.withValues(alpha: 0.9),
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: AppColors.white.withValues(alpha: 0.6),
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.ebonyClay,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: AppColors.white.withValues(alpha: 0.1)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1C1C1E), // iOS Dark system fill
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5),
        ),
        hintStyle: TextStyle(color: AppColors.white.withValues(alpha: 0.4)),
      ),

      iconTheme: const IconThemeData(color: AppColors.white),

      dividerTheme: DividerThemeData(
        color: AppColors.white.withValues(alpha: 0.1),
        thickness: 1,
      ),
    );
  }
}
