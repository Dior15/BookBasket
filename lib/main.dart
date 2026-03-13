import 'package:bookbasket/basket.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import "dart:io";
import 'package:epub_parser/epub_parser.dart' hide Image;

import 'auth_service.dart';
import 'login_page.dart';
import 'navigation/drawer_shell.dart';
import 'themes/theme_builder.dart';
import 'themes/theme_notifier.dart';

void main() async {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => BasketContentManager()..reload())
      ],
      child: const BookBasketApp(),
    ),
  );
}

class BookBasketApp extends StatelessWidget {
  const BookBasketApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    late ThemeData lightTheme;
    late ThemeData darkTheme;
    late ThemeMode themeMode;

    if (themeNotifier.themeType == ThemeType.advanced) {
      // Extract the fallback color for ThemeData from your Gradient
      Color fallbackColor = Colors.white;
      if (themeNotifier.backgroundColor is LinearGradient) {
        fallbackColor = (themeNotifier.backgroundColor as LinearGradient).colors.first;
      } else if (themeNotifier.backgroundColor is RadialGradient) {
        fallbackColor = (themeNotifier.backgroundColor as RadialGradient).colors.first;
      }

      final advancedTheme = buildAdvancedTheme(
        fallbackColor,
        themeNotifier.foregroundColor,
      );
      lightTheme = advancedTheme;
      darkTheme = advancedTheme;
      themeMode = ThemeMode.light;
    } else {
      // Kept your colleague's standard theme setups
      lightTheme = buildBookBasketTheme(Brightness.light);
      darkTheme = buildBookBasketTheme(Brightness.dark);
      themeMode = themeNotifier.themeType == ThemeType.light
          ? ThemeMode.light
          : ThemeMode.dark;
    }

    // Force transparent scaffold backgrounds on BOTH themes to allow the gradient to show
    lightTheme = lightTheme.copyWith(scaffoldBackgroundColor: Colors.transparent);
    darkTheme = darkTheme.copyWith(scaffoldBackgroundColor: Colors.transparent);

    return MaterialApp(
      title: 'BookBasket',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      // The Magic Wrap: Injecting the overarching app gradient!
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: themeNotifier.backgroundColor,
          ),
          child: child,
        );
      },
      home: const AuthGate(),
    );
  }
}

/// Reads persisted login state then routes to [LoginPage] or [DrawerShell].
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  bool _loggedIn = false;
  bool _admin = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loggedIn = await AuthService.isLoggedIn();
    final admin = loggedIn ? await AuthService.isAdmin() : false;
    if (!mounted) return;
    setState(() {
      _loggedIn = loggedIn;
      _admin = admin;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _loggedIn ? DrawerShell(isAdmin: _admin) : const LoginPage();
  }
}