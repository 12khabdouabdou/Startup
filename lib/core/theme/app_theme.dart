import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

abstract final class AppTheme {
  // ─── Light Theme ──────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Palette Integration
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary, // #2E7D32
        primaryContainer: AppColors.primaryLight,
        secondary: AppColors.secondary, // #8D6E63
        tertiary: AppColors.accent, // #FDD835
        error: AppColors.error,
        surface: AppColors.surface, // #F5F0E8
        onSurface: AppColors.onSurface,
        onPrimary: Colors.white,
      ),
      
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: AppTypography.textTheme,
      
      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),

      // Cards (AC-4: Radius 12-14px)
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Chips (AC-4: Radius 20px)
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaryLight.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // Buttons (AC-3: Min 56dp height)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(88, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.textTheme.labelLarge,
        ),
      ),
      
      // Text Buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Floating Action Buttons
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onSurface,
        elevation: 4,
      ),
      
      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.textSecondary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  // ─── Dark Theme ───────────────────────────────
  static ThemeData get darkTheme {
    const darkSurface = Color(0xFF1A1A2E);
    const darkCard = Color(0xFF16213E);
    const darkOnSurface = Color(0xFFECECEC);
    const darkInputFill = Color(0xFF1F2940);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: const Color(0xFF66BB6A), // Lighter green for dark bg
        primaryContainer: const Color(0xFF1B5E20),
        secondary: const Color(0xFFBCAAA4),
        tertiary: AppColors.accent,
        error: const Color(0xFFEF5350),
        surface: darkSurface,
        onSurface: darkOnSurface,
        onPrimary: Colors.black,
      ),

      scaffoldBackgroundColor: darkSurface,
      textTheme: AppTypography.textTheme.apply(
        bodyColor: darkOnSurface,
        displayColor: darkOnSurface,
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F3460),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),

      // Cards
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: darkCard,
        selectedColor: const Color(0xFF66BB6A).withValues(alpha: 0.25),
        labelStyle: const TextStyle(color: darkOnSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF66BB6A),
          foregroundColor: Colors.black,
          minimumSize: const Size(88, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.textTheme.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF81C784),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        elevation: 6,
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkInputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF66BB6A), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.08),
      ),
    );
  }
}
