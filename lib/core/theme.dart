import 'package:flutter/material.dart';

class AppTheme {
  /// ================= HEADER CONFIG =================

  static const String headerImage = "assets/header.png";
  static const double headerHeight = 140;
  static const Color headerOverlay = Colors.transparent;

  /// ================= USER / DEFAULT COLORS =================
  ///
  /// Existing User theme — intentionally unchanged.

  static const primary = Color(0xFF0E8C8D);
  static const primaryLight = Color(0xFF1DB6B7);
  static const primaryDark = Color(0xFF066B6C);

  static const background = Color(0xFFF4F6F8);
  static const card = Color(0xFFFFFFFF);
  static const text = Color(0xFF1F2933);

  /// ================= DARK BASE =================

  static const darkBackground = Color(0xFF0B0F10);
  static const darkCard = Color(0xFF151A1C);
  static const darkText = Color(0xFFFFFFFF);

  /// =========================================================
  /// ROLE COLORS
  /// =========================================================

  /// 👑 OWNER — Purple
  static const ownerPrimary = Color(0xFF7B1FA2);
  static const ownerPrimaryLight = Color(0xFFAB47BC);
  static const ownerPrimaryDark = Color(0xFF4A148C);

  /// 🛡️ ADMIN — Blue
  static const adminPrimary = Color(0xFF1565C0);
  static const adminPrimaryLight = Color(0xFF42A5F5);
  static const adminPrimaryDark = Color(0xFF0D47A1);

  /// 🟢 MUFTI — Green
  static const muftiPrimary = Color(0xFF2E7D32);
  static const muftiPrimaryLight = Color(0xFF66BB6A);
  static const muftiPrimaryDark = Color(0xFF1B5E20);

  /// 👤 USER — Existing Teal
  static const userPrimary = primary;
  static const userPrimaryLight = primaryLight;
  static const userPrimaryDark = primaryDark;

  /// =========================================================
  /// ROLE BACKGROUNDS
  /// =========================================================

  /// 👑 OWNER — Soft Lavender
  static const ownerBackground = Color(0xFFF3EAFB);

  /// 🛡️ ADMIN — Soft Blue
  static const adminBackground = Color(0xFFE7F1FD);

  /// 🟢 MUFTI — Soft Green
  static const muftiBackground = Color(0xFFE8F6EC);

  /// 👤 USER — Existing Background
  static const userBackground = background;

  /// =========================================================
  /// ROLE → PRIMARY COLOR
  /// =========================================================

  static Color primaryForRole(String role) {
    switch (role.trim().toLowerCase()) {
      case 'owner':
        return ownerPrimary;

      case 'admin':
        return adminPrimary;

      case 'mufti':
        return muftiPrimary;

      case 'user':
      default:
        return userPrimary;
    }
  }

  /// =========================================================
  /// ROLE → LIGHT PRIMARY COLOR
  /// =========================================================

  static Color primaryLightForRole(String role) {
    switch (role.trim().toLowerCase()) {
      case 'owner':
        return ownerPrimaryLight;

      case 'admin':
        return adminPrimaryLight;

      case 'mufti':
        return muftiPrimaryLight;

      case 'user':
      default:
        return userPrimaryLight;
    }
  }

  /// =========================================================
  /// ROLE → DARK PRIMARY COLOR
  /// =========================================================

  static Color primaryDarkForRole(String role) {
    switch (role.trim().toLowerCase()) {
      case 'owner':
        return ownerPrimaryDark;

      case 'admin':
        return adminPrimaryDark;

      case 'mufti':
        return muftiPrimaryDark;

      case 'user':
      default:
        return userPrimaryDark;
    }
  }

  /// =========================================================
  /// ROLE → BACKGROUND COLOR
  /// =========================================================

  static Color backgroundForRole(String role) {
    switch (role.trim().toLowerCase()) {
      case 'owner':
        return ownerBackground;

      case 'admin':
        return adminBackground;

      case 'mufti':
        return muftiBackground;

      case 'user':
      default:
        return userBackground;
    }
  }

  /// =========================================================
  /// LIGHT THEME
  /// =========================================================

  static ThemeData lightForRole(String role) {
    final rolePrimary = primaryForRole(role);
    final rolePrimaryLight = primaryLightForRole(role);
    final roleBackground = backgroundForRole(role);

    return ThemeData(
      useMaterial3: true,

      scaffoldBackgroundColor: roleBackground,

      colorScheme: ColorScheme(
        brightness: Brightness.light,

        primary: rolePrimary,
        onPrimary: Colors.white,

        secondary: rolePrimaryLight,
        onSecondary: Colors.white,

        error: Colors.red,
        onError: Colors.white,

        surface: card,
        onSurface: text,
      ),

      /// APP BAR
      appBarTheme: AppBarTheme(
        backgroundColor: rolePrimary,
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
          backgroundColor: rolePrimary,
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
  }

  /// =========================================================
  /// DARK THEME
  /// =========================================================

  static ThemeData darkForRole(String role) {
    final rolePrimary = primaryForRole(role);
    final rolePrimaryLight = primaryLightForRole(role);

    return ThemeData(
      useMaterial3: true,

      scaffoldBackgroundColor: darkBackground,

      colorScheme: ColorScheme(
        brightness: Brightness.dark,

        primary: rolePrimary,
        onPrimary: Colors.white,

        secondary: rolePrimaryLight,
        onSecondary: Colors.white,

        error: Colors.red,
        onError: Colors.white,

        surface: darkCard,
        onSurface: darkText,
      ),

      /// APP BAR
      appBarTheme: AppBarTheme(
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
          backgroundColor: rolePrimary,
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

  /// =========================================================
  /// DEFAULT THEMES
  ///
  /// Kept for compatibility with existing code.
  /// These represent the User / Teal theme.
  /// =========================================================

  static ThemeData light = lightForRole('user');

  static ThemeData dark = darkForRole('user');
}