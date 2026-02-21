import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_service.dart';
import 'login_page.dart';
import 'navigation/drawer_shell.dart';
import 'themes/theme_builder.dart';
import 'themes/theme_notifier.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const BookBasketApp(),
    ),
  );
}

class BookBasketApp extends StatelessWidget {
  const BookBasketApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    late final ThemeData lightTheme;
    late final ThemeData darkTheme;
    late final ThemeMode themeMode;

    if (themeNotifier.themeType == ThemeType.advanced) {
      final advancedTheme = buildAdvancedTheme(
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_loggedIn) return const LoginPage();
    return DrawerShell(isAdmin: _admin);
  }
}
