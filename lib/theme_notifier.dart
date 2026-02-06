import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  static const String key = "theme_mode";

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  ThemeNotifier() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(key);

    if (savedTheme == "dark") {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }

    notifyListeners();
  }

  Future<void> _saveTheme(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  void setLightMode() {
    _themeMode = ThemeMode.light;
    _saveTheme("light");
    notifyListeners();
  }

  void setDarkMode() {
    _themeMode = ThemeMode.dark;
    _saveTheme("dark");
    notifyListeners();
  }
}