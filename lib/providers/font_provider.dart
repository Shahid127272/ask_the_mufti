import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontProvider with ChangeNotifier {

  /// DEFAULT FONTS
  String questionFont = "Inter";
  String answerFont = "Roboto";
  String uiFont = "OpenSans";
  String headingFont = "Norwester";

  /// FONT SIZE
  double fontSize = 16;

  SharedPreferences? _prefs;

  /// LOAD SAVED SETTINGS
  Future<void> loadFonts() async {

    _prefs = await SharedPreferences.getInstance();

    questionFont =
        _prefs?.getString("question_font") ?? "Inter";

    answerFont =
        _prefs?.getString("answer_font") ?? "Roboto";

    uiFont =
        _prefs?.getString("ui_font") ?? "OpenSans";

    headingFont =
        _prefs?.getString("heading_font") ?? "Norwester";

    fontSize =
        _prefs?.getDouble("font_size") ?? 16;

    notifyListeners();
  }

  /// SET QUESTION FONT
  Future<void> setQuestionFont(String font) async {

    questionFont = font;

    await _prefs?.setString(
      "question_font",
      font,
    );

    notifyListeners();
  }

  /// SET ANSWER FONT
  Future<void> setAnswerFont(String font) async {

    answerFont = font;

    await _prefs?.setString(
      "answer_font",
      font,
    );

    notifyListeners();
  }

  /// SET UI FONT
  Future<void> setUIFont(String font) async {

    uiFont = font;

    await _prefs?.setString(
      "ui_font",
      font,
    );

    notifyListeners();
  }

  /// SET HEADING FONT
  Future<void> setHeadingFont(String font) async {

    headingFont = font;

    await _prefs?.setString(
      "heading_font",
      font,
    );

    notifyListeners();
  }

  /// SET FONT SIZE
  Future<void> setFontSize(double size) async {

    fontSize = size;

    await _prefs?.setDouble(
      "font_size",
      size,
    );

    notifyListeners();
  }

  /// RESET TO DEFAULT FONTS
  Future<void> resetFonts() async {

    questionFont = "Inter";
    answerFont = "Roboto";
    uiFont = "OpenSans";
    headingFont = "Norwester";
    fontSize = 16;

    await _prefs?.setString("question_font", questionFont);
    await _prefs?.setString("answer_font", answerFont);
    await _prefs?.setString("ui_font", uiFont);
    await _prefs?.setString("heading_font", headingFont);
    await _prefs?.setDouble("font_size", fontSize);

    notifyListeners();
  }

}