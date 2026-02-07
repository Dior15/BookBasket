import 'package:flutter/material.dart';

ThemeData buildAdvancedTheme(Color bg, Color fg) {
  final brightness = _estimateBrightnessForColor(bg);

  final baseTextTheme = brightness == Brightness.dark
      ? Typography.whiteMountainView
      : Typography.blackMountainView;

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

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: 0,
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

    // ListTiles
    listTileTheme: ListTileThemeData(
      iconColor: fg,
      textColor: fg,
    ),
  );
}

Brightness _estimateBrightnessForColor(Color color) {
  final luminance = color.computeLuminance();
  return luminance > 0.5 ? Brightness.light : Brightness.dark;
}