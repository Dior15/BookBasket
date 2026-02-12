import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'themes/theme_notifier.dart';
import 'themes/theme_builder.dart';

import 'preferences_page.dart';
import 'catalog.dart';
import 'basket.dart';
import 'admin.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    late final ThemeData lightTheme;
    late final ThemeData darkTheme;
    late final ThemeMode themeMode;

    // Apply Advanced theme
    if (themeNotifier.themeType == ThemeType.advanced) {
      final advancedTheme =
      buildAdvancedTheme(themeNotifier.backgroundColor, themeNotifier.foregroundColor);

      lightTheme = advancedTheme;
      darkTheme = advancedTheme;
      themeMode = ThemeMode.light;
    } else {
      // Normal Light/Dark
      lightTheme = ThemeData.light();
      darkTheme = ThemeData.dark();
      themeMode = themeNotifier.themeType == ThemeType.light
          ? ThemeMode.light
          : ThemeMode.dark;
    }

    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // Change the widget being returned to test different pages
    return const Basket();
  }
}