import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeType { light, dark, advanced }

class ThemeNotifier extends ChangeNotifier {
  static const String themeTypeKey = "theme_type";
  static const String bgKey = "background_color";
  static const String fgKey = "foreground_color";

  ThemeType _themeType = ThemeType.light;
  ThemeType get themeType => _themeType;

  Color _backgroundColor = Colors.white;
  Color get backgroundColor => _backgroundColor;

  Color _foregroundColor = Colors.black;
  Color get foregroundColor => _foregroundColor;

  ThemeNotifier() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final savedType = prefs.getString(themeTypeKey);
    if (savedType == "dark") {
      _themeType = ThemeType.dark;
    } else if (savedType == "advanced") {
      _themeType = ThemeType.advanced;
    } else {
      _themeType = ThemeType.light;
    }

    final bgValue = prefs.getInt(bgKey);
    if (bgValue != null) _backgroundColor = Color(bgValue);

    final fgValue = prefs.getInt(fgKey);
    if (fgValue != null) _foregroundColor = Color(fgValue);

    notifyListeners();
  }

  Future<void> _saveThemeType(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(themeTypeKey, value);
  }

  Future<void> _saveBackgroundColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(bgKey, color.value);
  }

  Future<void> _saveForegroundColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(fgKey, color.value);
  }

  void setLightMode() {
    _themeType = ThemeType.light;
    _saveThemeType("light");
    notifyListeners();
  }

  void setDarkMode() {
    _themeType = ThemeType.dark;
    _saveThemeType("dark");
    notifyListeners();
  }

  void setAdvancedMode() {
    _themeType = ThemeType.advanced;
    _saveThemeType("advanced");
    notifyListeners();
  }

  void setBackgroundColor(Color color) {
    _backgroundColor = color;
    _saveBackgroundColor(color);
    notifyListeners();
  }

  void setForegroundColor(Color color) {
    _foregroundColor = color;
    _saveForegroundColor(color);
    notifyListeners();
  }
}