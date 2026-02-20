import 'package:flutter/material.dart';

import '../admin.dart';
import '../basket.dart';
import '../catalog.dart';
import '../login_page.dart';
import '../preferences_page.dart';
import '../search.dart';
import 'app_drawer.dart';

class DrawerShell extends StatefulWidget {
  final int initialIndex;

  const DrawerShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<DrawerShell> createState() => _DrawerShellState();
}

class _DrawerShellState extends State<DrawerShell> {
  late int _index;

  late final List<DrawerDestination> _destinations = [
    DrawerDestination(
      title: 'Catalog',
      icon: Icons.book,
      builder: (_) => const Catalog(),
    ),
    DrawerDestination(
      title: 'Search',
      icon: Icons.search,
      builder: (_) => const Search(), // ✅ fixed (was SearchPage)
    ),
    DrawerDestination(
      title: 'Basket',
      icon: Icons.shopping_basket,
      builder: (_) => const Basket(),
    ),
    DrawerDestination(
      title: 'Preferences',
      icon: Icons.tune,
      builder: (_) => const PreferencesPage(),
    ),
    DrawerDestination(
      title: 'Admin',
      icon: Icons.admin_panel_settings,
      builder: (_) => const AdminPage(),
    ),
    DrawerDestination(
      title: 'Login',
      icon: Icons.login,
      builder: (_) => const LoginPage(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, _destinations.length - 1);
  }

  void _selectIndex(int newIndex) {
    if (newIndex == _index) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _index = newIndex;
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: Text(_destinations[_index].title),
      ),
      drawer: AppDrawer(
        selectedIndex: _index,
        onSelect: _selectIndex,
        destinations: _destinations,
      ),
      body: IndexedStack(
        index: _index,
        children: _destinations
            .map((destination) => Builder(builder: destination.builder))
            .toList(),
      ),
    );
  }
}