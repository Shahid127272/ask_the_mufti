import 'package:flutter/material.dart';

class AppTheme {

  /// ================= HEADER CONFIG (GLOBAL CONTROL) =================

  // 🔥 Header Image Path (change here only)
  static const String headerImage = "assets/header.png";

  // 🔥 Header Height
  static const double headerHeight = 140;

  // 🔥 Optional overlay (keep transparent for clean look)
  static const Color headerOverlay = Colors.transparent;

  /// ================= MAIN COLORS (Islamic Teal Theme) =================

  static const primary = Color(0xFF0E8C8D);
  static const primaryLight = Color(0xFF1DB6B7);
  static const primaryDark = Color(0xFF066B6C);

  static const background = Color(0xFFF4F6F8);
  static const card = Color(0xFFFFFFFF);

  static const text = Color(0xFF1F2933);

  /// ================= DARK =================

  static const darkBackground = Color(0xFF0B0F10);
  static const darkCard = Color(0xFF151A1C);
  static const darkText = Color(0xFFFFFFFF);

  // ================= LIGHT THEME =================

  static ThemeData light = ThemeData(
    useMaterial3: true,

    scaffoldBackgroundColor: background,

    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      secondary: primaryLight,
      onSecondary: Colors.white,
      error: Colors.red,
      onError: Colors.white,
      surface: card,
      onSurface: text,
    ),

    /// APP BAR
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    ),

    /// CARDS
    cardTheme: CardThemeData(
      color: card,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),

    /// ICONS
    iconTheme: const IconThemeData(
      color: text,
    ),

    /// BUTTON
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),

    /// TEXT
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: text,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: text,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        color: text,
      ),
    ),
  );

  // ================= DARK THEME =================

  static ThemeData dark = ThemeData(
    useMaterial3: true,

    scaffoldBackgroundColor: darkBackground,

    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: Colors.white,
      secondary: primaryLight,
      onSecondary: Colors.white,
      error: Colors.red,
      onError: Colors.white,
      surface: darkCard,
      onSurface: darkText,
    ),

    /// APP BAR
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      foregroundColor: darkText,
      centerTitle: true,
      elevation: 0,
    ),

    /// CARDS
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),

    /// ICONS
    iconTheme: const IconThemeData(
      color: darkText,
    ),

    /// BUTTON
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),

    /// TEXT
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: darkText,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: darkText,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        color: darkText,
      ),
    ),
  );
}