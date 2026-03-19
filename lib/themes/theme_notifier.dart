import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeType { light, dark, advanced }

class ThemeNotifier extends ChangeNotifier {
  ThemeType _themeType = ThemeType.light;

  // CHANGED: The background is explicitly a Gradient now
  Gradient _backgroundColor = const LinearGradient(
    colors: [Colors.white, Colors.white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  Color _foregroundColor = Colors.black;

  ThemeType get themeType => _themeType;
  Gradient get backgroundColor => _backgroundColor; // Returns a Gradient
  Color get foregroundColor => _foregroundColor;

  ThemeNotifier() {
    _loadFromPrefs();
  }

  void setLightMode() {
    _themeType = ThemeType.light;
    _backgroundColor = const LinearGradient(
      colors: [Colors.white, Colors.white],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
    _foregroundColor = Colors.black;
    _saveToPrefs();
    notifyListeners();
  }

  void setDarkMode() {
    _themeType = ThemeType.dark;
    _backgroundColor = const LinearGradient(
      colors: [Color(0xFF1C1C1C), Color(0xFF000000)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
    _foregroundColor = Colors.white;
    _saveToPrefs();
    notifyListeners();
  }

  void setAdvancedMode() {
    _themeType = ThemeType.advanced;
    _saveToPrefs();
    notifyListeners();
  }

  // CHANGED: Accepts a Gradient instead of a Color
  void setBackgroundColor(Gradient gradient) {
    _backgroundColor = gradient;
    _saveToPrefs();
    notifyListeners();
  }

  void setForegroundColor(Color color) {
    _foregroundColor = color;
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Theme Type
    final themeString = prefs.getString('theme_type') ?? 'light';
    _themeType = ThemeType.values.firstWhere(
            (e) => e.name == themeString,
        orElse: () => ThemeType.light
    );

    // Load Foreground Color
    final fgValue = prefs.getInt('foreground_color') ?? Colors.black.value;
    _foregroundColor = Color(fgValue);

    // Load Background Gradient
    final bgColorsString = prefs.getStringList('background_gradient_colors');
    if (bgColorsString != null && bgColorsString.isNotEmpty) {
      final colors = bgColorsString.map((s) => Color(int.parse(s))).toList();
      _backgroundColor = LinearGradient(
        colors: colors,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else {
      // Fallback default if nothing is saved
      _backgroundColor = const LinearGradient(
        colors: [Colors.white, Colors.white],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    }

    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('theme_type', _themeType.name);
    await prefs.setInt('foreground_color', _foregroundColor.value);

    // Save Background Gradient
    if (_backgroundColor is LinearGradient) {
      final linearGradient = _backgroundColor as LinearGradient;
      final colorStrings = linearGradient.colors.map((c) => c.value.toString()).toList();
      await prefs.setStringList('background_gradient_colors', colorStrings);
    }
  }
}