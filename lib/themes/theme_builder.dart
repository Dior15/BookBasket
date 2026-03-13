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
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selectedColor: colorScheme.primary.withOpacity(0.18),
      backgroundColor: surface,
      labelStyle: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
      side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.7)),
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      tileColor: surface,
      iconColor: colorScheme.onSurfaceVariant,
      textColor: colorScheme.onSurface,
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant.withOpacity(0.65),
      thickness: 1,
      space: 20,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

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