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

    // 1. We build the base theme depending on the mode
    late ThemeData activeTheme;

    if (themeNotifier.themeType == ThemeType.advanced) {
      // For advanced, we pass the first color of the gradient as a fallback
      // for things like AppBars, but the true background will be transparent.
      activeTheme = buildAdvancedTheme(
        themeNotifier.backgroundColor.colors.first,
        themeNotifier.foregroundColor,
      );
    } else if (themeNotifier.themeType == ThemeType.dark) {
      activeTheme = ThemeData.dark();
    } else {
      activeTheme = ThemeData.light();
    }

    // 2. We force the scaffold background to be transparent across the ENTIRE app
    activeTheme = activeTheme.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
    );

    return MaterialApp(
      title: 'BookBasket',
      debugShowCheckedModeBanner: false,
      theme: activeTheme,

      // 3. THE MAGIC: We wrap the entire navigation stack in your gradient!
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: themeNotifier.backgroundColor, // Your global gradient!
          ),
          child: child, // All your transparent Scaffolds will render on top of this
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_loggedIn) return const LoginPage();
    return DrawerShell(isAdmin: _admin);
  }
}
