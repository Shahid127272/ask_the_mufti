import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  SharedPreferences? _prefs;

  Future<void> loadTheme() async {

    _prefs = await SharedPreferences.getInstance();

    final theme = _prefs?.getString("app_theme") ?? "light";

    switch (theme) {
      case "dark":
        _themeMode = ThemeMode.dark;
        break;

      case "system":
        _themeMode = ThemeMode.system;
        break;

      default:
        _themeMode = ThemeMode.light;
    }

    notifyListeners();
  }

  Future<void> setTheme(String value) async {

    await _prefs?.setString("app_theme", value);

    switch (value) {
      case "dark":
        _themeMode = ThemeMode.dark;
        break;

      case "system":
        _themeMode = ThemeMode.system;
        break;

      default:
        _themeMode = ThemeMode.light;
    }

    notifyListeners();
  }
}