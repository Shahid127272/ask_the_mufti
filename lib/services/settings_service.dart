import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {

  /// FONT SIZE
  static Future<double> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble("fontSize") ?? 16;
  }

  static Future<void> setFontSize(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble("fontSize", value);
  }

  /// THEME
  static Future<String> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("theme") ?? "system";
  }

  static Future<void> setTheme(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("theme", value);
  }

  /// FONT STYLE
  static Future<String> getFont() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("font") ?? "Default";
  }

  static Future<void> setFont(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("font", value);
  }

  /// QUESTION COLOR
  static Future<int> getQuestionColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("questionColor") ?? 0xFF1565C0;
  }

  static Future<void> setQuestionColor(int color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("questionColor", color);
  }

  /// ANSWER COLOR
  static Future<int> getAnswerColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("answerColor") ?? 0xFF2E7D32;
  }

  static Future<void> setAnswerColor(int color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("answerColor", color);
  }

}