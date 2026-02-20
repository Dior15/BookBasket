import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'themes/theme_notifier.dart';
import 'themes/theme_builder.dart';

import 'basket.dart';
import 'admin.dart';
import 'login_page.dart';
import 'auth_service.dart';

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
      final advancedTheme = buildAdvancedTheme(
        themeNotifier.backgroundColor,
        themeNotifier.foregroundColor,
      );

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
      title: 'BookBasket',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  bool _loggedIn = false;
  bool _admin = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final loggedIn = await AuthService.isLoggedIn();
      final admin = loggedIn ? await AuthService.isAdmin() : false;

      if (!mounted) return;
      setState(() {
        _loggedIn = loggedIn;
        _admin = admin;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Auth load failed: $e';
        _loading = false;
      });
    }
  }

  Future<void> _forceSignOut() async {
    // If your AuthService has logout(), this will work immediately.
    // If it doesn’t, uninstall/clear app storage once, or paste auth_service.dart
    // and I’ll add a proper logout() method that clears SharedPreferences.
    try {
      await AuthService.logout();
    } catch (_) {
      // ignore so you can still escape even if logout isn't implemented
    }

    if (!mounted) return;
    setState(() {
      _loggedIn = false;
      _admin = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_error!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    if (!_loggedIn) return const LoginPage();

    if (_admin) {
      // ✅ Admin page + an "escape hatch" logout button so you're never stuck
      return Scaffold(
        body: const AdminPage(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _forceSignOut,
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      );
    }

    return const Basket();
  }
}