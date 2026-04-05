import 'package:flutter/material.dart';

import '../auth_service.dart';
import '../firebase_database/firebase_db.dart';

enum ThemeType { light, dark, advanced }

class ThemeNotifier extends ChangeNotifier {
  ThemeType _themeType = ThemeType.light;

  Gradient _backgroundColor = const LinearGradient(
    colors: [Colors.white, Colors.white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  Color _foregroundColor = Colors.black;

  ThemeType get themeType => _themeType;
  Gradient get backgroundColor => _backgroundColor;
  Color get foregroundColor => _foregroundColor;

  ThemeNotifier() {
    loadFromCloud();
  }

  void setLightMode() {
    _themeType = ThemeType.light;
    _backgroundColor = const LinearGradient(
      colors: [Colors.white, Colors.white],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
    _foregroundColor = Colors.black;
    _saveToCloud();
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
    _saveToCloud();
    notifyListeners();
  }

  void setAdvancedMode() {
    _themeType = ThemeType.advanced;
    _saveToCloud();
    notifyListeners();
  }

  void setBackgroundColor(Gradient gradient) {
    _backgroundColor = gradient;
    _saveToCloud();
    notifyListeners();
  }

  void setForegroundColor(Color color) {
    _foregroundColor = color;
    _saveToCloud();
    notifyListeners();
  }

  // --- NEW: Load App Theme from Firebase ---
  Future<void> loadFromCloud() async {
    try {
      final email = await AuthService.getEmail() ?? AuthService.userEmail;
      final prefs = await FirebaseDB.getReference().getUserPreferences(email);

      // Load Theme Type
      final themeString = prefs['theme_type'] ?? 'light';
      _themeType = ThemeType.values.firstWhere(
              (e) => e.name == themeString,
          orElse: () => ThemeType.light
      );

      // Load Foreground Color
      final fgValue = prefs['foreground_color'] ?? Colors.black.value;
      _foregroundColor = Color(fgValue);

      // Load Background Gradient
      final bgColorsString = prefs['background_gradient_colors'];
      if (bgColorsString != null && (bgColorsString as List).isNotEmpty) {
        final colors = (bgColorsString as List).map((s) => Color(int.parse(s.toString()))).toList();
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
    } catch (e) {
      debugPrint("Error loading cloud theme preferences: $e");
    }
  }

  // --- NEW: Save App Theme to Firebase ---
  Future<void> _saveToCloud() async {
    try {
      final email = await AuthService.getEmail() ?? AuthService.userEmail;

      Map<String, dynamic> newPrefs = {
        'theme_type': _themeType.name,
        'foreground_color': _foregroundColor.value,
      };

      // Save Background Gradient
      if (_backgroundColor is LinearGradient) {
        final linearGradient = _backgroundColor as LinearGradient;
        final colorStrings = linearGradient.colors.map((c) => c.value.toString()).toList();
        newPrefs['background_gradient_colors'] = colorStrings;
      }

      await FirebaseDB.getReference().updateUserPreference(email, newPrefs);

    } catch (e) {
      debugPrint("Error saving theme to cloud: $e");
    }
  }
}