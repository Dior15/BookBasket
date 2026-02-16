import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../themes/theme_builder.dart';
import '../themes/theme_notifier.dart';
import 'drawer_shell.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const DrawerApp(),
    ),
  );
}

class DrawerApp extends StatelessWidget {
  const DrawerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    late final ThemeData lightTheme;
    late final ThemeData darkTheme;
    late final ThemeMode themeMode;

    if (themeNotifier.themeType == ThemeType.advanced) {
      final advancedTheme =
          buildAdvancedTheme(
            themeNotifier.backgroundColor,
            themeNotifier.foregroundColor,
          );

      lightTheme = advancedTheme;
      darkTheme = advancedTheme;
      themeMode = ThemeMode.light;
    } else {
      lightTheme = ThemeData.light();
      darkTheme = ThemeData.dark();
      themeMode = themeNotifier.themeType == ThemeType.light
          ? ThemeMode.light
          : ThemeMode.dark;
    }

    return MaterialApp(
      title: 'BookBasket',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: const DrawerShell(),
    );
  }
}
