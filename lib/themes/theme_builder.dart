import 'package:flutter/material.dart';

ThemeData buildBookBasketTheme(Brightness brightness) {
  final bool isDark = brightness == Brightness.dark;
  final Color primary = isDark ? const Color(0xFF8FA7FF) : const Color(0xFF3949AB);
  final Color secondary = isDark ? const Color(0xFFB39DDB) : const Color(0xFF8A65EC);
  final Color background = isDark ? const Color(0xFF0F111A) : const Color(0xFFF4F6FB);
  final Color surface = isDark ? const Color(0xFF171A24) : Colors.white;

  final colorScheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: brightness,
    primary: primary,
    secondary: secondary,
    surface: surface,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: background,

    // FIX: Updated standard AppBar to respect the current surface text color
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface, // Forces icons/text to contrast the background
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      titleTextStyle: TextStyle(
        color: colorScheme.onSurface, // Explicitly colors the title text
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

ThemeData buildAdvancedTheme(Color bg, Color fg) {
  final brightness = ThemeData.estimateBrightnessForColor(bg);
  final baseTextTheme = ThemeData(brightness: brightness).textTheme;

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: fg,
    onPrimary: bg,
    secondary: fg,
    onSecondary: bg,
    background: bg,
    onBackground: fg,
    surface: bg,
    onSurface: fg,
    error: Colors.red,
    onError: Colors.white,
  );

  return ThemeData(
    brightness: brightness,
    scaffoldBackgroundColor: bg,
    colorScheme: colorScheme,

    // FIX: Updated Advanced AppBar to strictly use your selected fg color
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent, // Let the global gradient show through!
      foregroundColor: fg,
      elevation: 0,
      iconTheme: IconThemeData(color: fg), // Forces back buttons and menu icons to match
      titleTextStyle: TextStyle(
        color: fg, // Explicitly colors the title text
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    ),

    // Text
    textTheme: baseTextTheme.apply(
      bodyColor: fg,
      displayColor: fg,
    ),

    // Icons
    iconTheme: IconThemeData(color: fg),
    primaryIconTheme: IconThemeData(color: fg),

    // Dividers
    dividerColor: fg.withOpacity(0.3),

    // Radios
    radioTheme: RadioThemeData(
      fillColor: MaterialStatePropertyAll(fg),
    ),

    // Checkboxes
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStatePropertyAll(fg),
      checkColor: MaterialStatePropertyAll(bg),
    ),

    // Switches
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStatePropertyAll(fg),
      trackColor: MaterialStatePropertyAll(fg.withOpacity(0.5)),
    ),
  );
}