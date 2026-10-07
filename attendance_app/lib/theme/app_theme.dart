import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme Colors (Clean, bright, modern)
  static const Color lightBg = Color(0xFFF6F8F7);
  static const Color lightFg = Color(0xFF16201D);
  static const Color lightMuted = Color(0xFF5E6D67);
  static const Color lightPanel = Color(0xFFFFFFFF);
  static const Color lightLine = Color(0xFFE2E8E5);
  static const Color lightAccent = Color(0xFF0B6E63);
  static const Color lightSoft = Color(0xFFE6F3F0);

  // Dark Theme Colors
  static const Color darkBg = Color(0xFF0F1513);
  static const Color darkFg = Color(0xFFE6ECE9);
  static const Color darkMuted = Color(0xFF9BABA5);
  static const Color darkPanel = Color(0xFF161E1B);
  static const Color darkLine = Color(0xFF27332F);
  static const Color darkAccent = Color(0xFF3CCFB8);
  static const Color darkSoft = Color(0xFF173029);

  // Status Indicator Colors
  static const Color statusPresent = Color(0xFF10B981); // Emerald
  static const Color statusLate = Color(0xFFF59E0B);    // Amber
  static const Color statusAbsent = Color(0xFFEF4444);  // Red
  static const Color statusExcused = Color(0xFF2563EB); // Royal Blue

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        primary: lightAccent,
        secondary: lightAccent,
        surface: lightPanel,
        onPrimary: Colors.white,
        onSurface: lightFg,
        outline: lightLine,
      ),
      cardTheme: CardThemeData(
        color: lightPanel,
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: lightLine, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightPanel,
        foregroundColor: lightFg,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0.5,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightPanel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightAccent, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: darkAccent,
        secondary: darkAccent,
        surface: darkPanel,
        onPrimary: Color(0xFF072722),
        onSurface: darkFg,
        outline: darkLine,
      ),
      cardTheme: CardThemeData(
        color: darkPanel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: darkLine, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkPanel,
        foregroundColor: darkFg,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkAccent,
          foregroundColor: const Color(0xFF072722),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkPanel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkAccent, width: 1.5),
        ),
      ),
    );
  }
}
