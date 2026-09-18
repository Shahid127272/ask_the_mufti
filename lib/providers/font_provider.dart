import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontProvider with ChangeNotifier {
  // =========================================================
  // FONT CONSTANTS
  // =========================================================

  static const String systemDefault = 'System Default';

  static const List<String> availableFonts = [
    systemDefault,
    'Inter',
    'OpenSans',
    'Roboto',
    'Playfair',
    'Norwester',
    'PatrickHand',
    'PrimeNordic',
    'Nilmero',
    'Noaction',
    'TaoBaso',
    'SanToremi',
    'BiotripSerifCaps',
    'Cafecito',
    'Stylis',
  ];

  // =========================================================
  // DEFAULT FONTS
  // =========================================================

  String questionFont = 'Inter';
  String answerFont = 'Roboto';
  String uiFont = 'OpenSans';
  String headingFont = 'Norwester';

  // =========================================================
  // FONT SIZE
  // =========================================================

  double fontSize = 16;

  // =========================================================
  // FONT WEIGHT
  // =========================================================

  FontWeight fontWeight = FontWeight.w400;

  // =========================================================
  // ITALIC
  // =========================================================

  bool isItalic = false;

  // =========================================================
  // SHARED PREFERENCES
  // =========================================================

  SharedPreferences? _prefs;

  // =========================================================
  // STORAGE KEYS
  // =========================================================

  static const String _questionFontKey =
      'question_font';

  static const String _answerFontKey =
      'answer_font';

  static const String _uiFontKey =
      'ui_font';

  static const String _headingFontKey =
      'heading_font';

  static const String _fontSizeKey =
      'font_size';

  static const String _fontWeightKey =
      'font_weight';

  static const String _italicKey =
      'font_italic';

  // =========================================================
  // LOAD SAVED SETTINGS
  // =========================================================

  Future<void> loadFonts() async {
    _prefs =
    await SharedPreferences.getInstance();

    questionFont =
        _prefs?.getString(
          _questionFontKey,
        ) ??
            'Inter';

    answerFont =
        _prefs?.getString(
          _answerFontKey,
        ) ??
            'Roboto';

    uiFont =
        _prefs?.getString(
          _uiFontKey,
        ) ??
            'OpenSans';

    headingFont =
        _prefs?.getString(
          _headingFontKey,
        ) ??
            'Norwester';

    fontSize =
        _prefs?.getDouble(
          _fontSizeKey,
        ) ??
            16;

    final savedWeight =
        _prefs?.getInt(
          _fontWeightKey,
        ) ??
            400;

    fontWeight =
        _fontWeightFromValue(
          savedWeight,
        );

    isItalic =
        _prefs?.getBool(
          _italicKey,
        ) ??
            false;

    // ---------------------------------------------------------
    // SAFETY CHECK
    // ---------------------------------------------------------

    if (!availableFonts.contains(
      questionFont,
    )) {
      questionFont = 'Inter';
    }

    if (!availableFonts.contains(
      answerFont,
    )) {
      answerFont = 'Roboto';
    }

    if (!availableFonts.contains(
      uiFont,
    )) {
      uiFont = 'OpenSans';
    }

    if (!availableFonts.contains(
      headingFont,
    )) {
      headingFont = 'Norwester';
    }

    notifyListeners();
  }

  // =========================================================
  // SET QUESTION FONT
  // =========================================================

  Future<void> setQuestionFont(
      String font,
      ) async {
    if (!availableFonts.contains(font)) {
      return;
    }

    questionFont = font;

    await _prefs?.setString(
      _questionFontKey,
      font,
    );

    notifyListeners();
  }

  // =========================================================
  // SET ANSWER FONT
  // =========================================================

  Future<void> setAnswerFont(
      String font,
      ) async {
    if (!availableFonts.contains(font)) {
      return;
    }

    answerFont = font;

    await _prefs?.setString(
      _answerFontKey,
      font,
    );

    notifyListeners();
  }

  // =========================================================
  // SET UI FONT
  // =========================================================

  Future<void> setUIFont(
      String font,
      ) async {
    if (!availableFonts.contains(font)) {
      return;
    }

    uiFont = font;

    await _prefs?.setString(
      _uiFontKey,
      font,
    );

    notifyListeners();
  }

  // =========================================================
  // SET HEADING FONT
  // =========================================================

  Future<void> setHeadingFont(
      String font,
      ) async {
    if (!availableFonts.contains(font)) {
      return;
    }

    headingFont = font;

    await _prefs?.setString(
      _headingFontKey,
      font,
    );

    notifyListeners();
  }

  // =========================================================
  // SET FONT SIZE
  // =========================================================

  Future<void> setFontSize(
      double size,
      ) async {
    final safeSize =
    size.clamp(
      12.0,
      28.0,
    );

    fontSize =
        safeSize.toDouble();

    await _prefs?.setDouble(
      _fontSizeKey,
      fontSize,
    );

    notifyListeners();
  }

  // =========================================================
  // DECREASE FONT SIZE
  // =========================================================

  Future<void> decreaseFontSize() async {
    final newSize =
    (fontSize - 1)
        .clamp(
      12.0,
      28.0,
    )
        .toDouble();

    await setFontSize(
      newSize,
    );
  }

  // =========================================================
  // INCREASE FONT SIZE
  // =========================================================

  Future<void> increaseFontSize() async {
    final newSize =
    (fontSize + 1)
        .clamp(
      12.0,
      28.0,
    )
        .toDouble();

    await setFontSize(
      newSize,
    );
  }

  // =========================================================
  // SET FONT WEIGHT
  // =========================================================

  Future<void> setFontWeight(
      FontWeight weight,
      ) async {
    fontWeight = weight;

    await _prefs?.setInt(
      _fontWeightKey,
      _fontWeightValue(weight),
    );

    notifyListeners();
  }

  // =========================================================
  // SET ITALIC
  // =========================================================

  Future<void> setItalic(
      bool value,
      ) async {
    isItalic = value;

    await _prefs?.setBool(
      _italicKey,
      value,
    );

    notifyListeners();
  }

  // =========================================================
  // TOGGLE ITALIC
  // =========================================================

  Future<void> toggleItalic() async {
    await setItalic(
      !isItalic,
    );
  }

  // =========================================================
  // FONT WEIGHT → INTEGER
  // =========================================================

  int _fontWeightValue(
      FontWeight weight,
      ) {
    switch (weight) {
      case FontWeight.w100:
        return 100;

      case FontWeight.w200:
        return 200;

      case FontWeight.w300:
        return 300;

      case FontWeight.w400:
        return 400;

      case FontWeight.w500:
        return 500;

      case FontWeight.w600:
        return 600;

      case FontWeight.w700:
        return 700;

      case FontWeight.w800:
        return 800;

      case FontWeight.w900:
        return 900;

      default:
        return 400;
    }
  }

  // =========================================================
  // INTEGER → FONT WEIGHT
  // =========================================================

  FontWeight _fontWeightFromValue(
      int value,
      ) {
    switch (value) {
      case 100:
        return FontWeight.w100;

      case 200:
        return FontWeight.w200;

      case 300:
        return FontWeight.w300;

      case 500:
        return FontWeight.w500;

      case 600:
        return FontWeight.w600;

      case 700:
        return FontWeight.w700;

      case 800:
        return FontWeight.w800;

      case 900:
        return FontWeight.w900;

      case 400:
      default:
        return FontWeight.w400;
    }
  }

  // =========================================================
  // FONT WEIGHT LABEL
  // =========================================================

  String get fontWeightLabel {
    switch (fontWeight) {
      case FontWeight.w100:
        return 'Light';

      case FontWeight.w200:
        return 'Extra Light';

      case FontWeight.w300:
        return 'Light';

      case FontWeight.w500:
        return 'Medium';

      case FontWeight.w600:
        return 'Semi Bold';

      case FontWeight.w700:
        return 'Bold';

      case FontWeight.w800:
        return 'Extra Bold';

      case FontWeight.w900:
        return 'Black';

      case FontWeight.w400:
      default:
        return 'Regular';
    }
  }

  // =========================================================
  // SYSTEM DEFAULT HELPER
  // =========================================================

  String? resolveFontFamily(
      String font,
      ) {
    if (font == systemDefault) {
      return null;
    }

    return font;
  }

  // =========================================================
  // RESET ALL FONT SETTINGS
  // =========================================================

  Future<void> resetFonts() async {
    questionFont = 'Inter';
    answerFont = 'Roboto';
    uiFont = 'OpenSans';
    headingFont = 'Norwester';

    fontSize = 16;

    fontWeight =
        FontWeight.w400;

    isItalic = false;

    await _prefs?.setString(
      _questionFontKey,
      questionFont,
    );

    await _prefs?.setString(
      _answerFontKey,
      answerFont,
    );

    await _prefs?.setString(
      _uiFontKey,
      uiFont,
    );

    await _prefs?.setString(
      _headingFontKey,
      headingFont,
    );

    await _prefs?.setDouble(
      _fontSizeKey,
      fontSize,
    );

    await _prefs?.setInt(
      _fontWeightKey,
      400,
    );

    await _prefs?.setBool(
      _italicKey,
      false,
    );

    notifyListeners();
  }
}