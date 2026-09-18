import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  // =========================================================
  // DEFAULT COLORS
  // =========================================================

  static const int defaultQuestionColor = 0xFF1565C0;
  static const int defaultAnswerColor = 0xFF2E7D32;

  // =========================================================
  // STORAGE KEYS
  // =========================================================

  static const String _themeKey = 'theme';

  static const String _questionColorKey =
      'questionColor';

  static const String _answerColorKey =
      'answerColor';

  static const String _questionColorSystemKey =
      'questionColorSystem';

  static const String _answerColorSystemKey =
      'answerColorSystem';

  // =========================================================
  // THEME
  // =========================================================

  static Future<String> getTheme() async {
    final prefs =
    await SharedPreferences.getInstance();

    return prefs.getString(
      _themeKey,
    ) ??
        'system';
  }

  static Future<void> setTheme(
      String value,
      ) async {
    final prefs =
    await SharedPreferences.getInstance();

    await prefs.setString(
      _themeKey,
      value,
    );
  }

  // =========================================================
  // QUESTION COLOR
  // =========================================================

  /// Returns the saved question color.
  ///
  /// If System Default is selected, this returns the
  /// fallback default color. Use [isQuestionColorSystem]
  /// to determine whether the app should actually use
  /// the current system/theme color.
  static Future<int> getQuestionColor() async {
    final prefs =
    await SharedPreferences.getInstance();

    return prefs.getInt(
      _questionColorKey,
    ) ??
        defaultQuestionColor;
  }

  /// Saves a custom question color.
  static Future<void> setQuestionColor(
      int color,
      ) async {
    final prefs =
    await SharedPreferences.getInstance();

    await prefs.setInt(
      _questionColorKey,
      color,
    );

    await prefs.setBool(
      _questionColorSystemKey,
      false,
    );
  }

  // =========================================================
  // QUESTION COLOR — SYSTEM DEFAULT
  // =========================================================

  static Future<bool> isQuestionColorSystem() async {
    final prefs =
    await SharedPreferences.getInstance();

    return prefs.getBool(
      _questionColorSystemKey,
    ) ??
        true;
  }

  static Future<void> setQuestionColorSystem(
      bool value,
      ) async {
    final prefs =
    await SharedPreferences.getInstance();

    await prefs.setBool(
      _questionColorSystemKey,
      value,
    );
  }

  // =========================================================
  // ANSWER COLOR
  // =========================================================

  /// Returns the saved answer color.
  ///
  /// If System Default is selected, this returns the
  /// fallback default color. Use [isAnswerColorSystem]
  /// to determine whether the app should actually use
  /// the current system/theme color.
  static Future<int> getAnswerColor() async {
    final prefs =
    await SharedPreferences.getInstance();

    return prefs.getInt(
      _answerColorKey,
    ) ??
        defaultAnswerColor;
  }

  /// Saves a custom answer color.
  static Future<void> setAnswerColor(
      int color,
      ) async {
    final prefs =
    await SharedPreferences.getInstance();

    await prefs.setInt(
      _answerColorKey,
      color,
    );

    await prefs.setBool(
      _answerColorSystemKey,
      false,
    );
  }

  // =========================================================
  // ANSWER COLOR — SYSTEM DEFAULT
  // =========================================================

  static Future<bool> isAnswerColorSystem() async {
    final prefs =
    await SharedPreferences.getInstance();

    return prefs.getBool(
      _answerColorSystemKey,
    ) ??
        true;
  }

  static Future<void> setAnswerColorSystem(
      bool value,
      ) async {
    final prefs =
    await SharedPreferences.getInstance();

    await prefs.setBool(
      _answerColorSystemKey,
      value,
    );
  }

  // =========================================================
  // RESET READING SETTINGS
  // =========================================================

  static Future<void> resetReadingSettings() async {
    final prefs =
    await SharedPreferences.getInstance();

    // System Default
    await prefs.setBool(
      _questionColorSystemKey,
      true,
    );

    await prefs.setBool(
      _answerColorSystemKey,
      true,
    );

    // Keep fallback values available
    await prefs.setInt(
      _questionColorKey,
      defaultQuestionColor,
    );

    await prefs.setInt(
      _answerColorKey,
      defaultAnswerColor,
    );
  }
}