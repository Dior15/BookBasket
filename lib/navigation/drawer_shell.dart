import 'package:bookbasket/map/map.dart';
import 'package:flutter/material.dart';

import '../admin.dart';
import '../auth_service.dart';
import '../basket.dart';
import '../catalog.dart';
import '../login_page.dart';
import '../preferences_page.dart';
import '../search.dart';
import 'app_drawer.dart';
import '../friends_list.dart';

class DrawerShell extends StatefulWidget {
  /// When [isAdmin] is true the Admin panel destination is included.
  final bool isAdmin;

  const DrawerShell({super.key, this.isAdmin = false});

  @override
  State<DrawerShell> createState() => _DrawerShellState();
}

class _DrawerShellState extends State<DrawerShell> {
  late int _index;
  late final List<DrawerDestination> _destinations;

  @override
  void initState() {
    super.initState();
    _destinations = _buildDestinations(widget.isAdmin);
    _index = 0;
  }

  List<DrawerDestination> _buildDestinations(bool isAdmin) {
    return [
      DrawerDestination(
        title: 'Catalog',
        icon: Icons.book,
        builder: (_) => const Catalog(),
      ),
      DrawerDestination(
        title: 'Search',
        icon: Icons.search,
        builder: (_) => const Search(),
      ),
      DrawerDestination(
        title: 'Basket',
        icon: Icons.shopping_basket,
        builder: (_) => Basket(),
        // builder: (_) => Basket(key: UniqueKey()),
      ),
      DrawerDestination(
        title: 'Reading Map',
        icon: Icons.map,
        builder: (_) => MapPage(),
      ),
      DrawerDestination(
        title: 'Friends',
        icon: Icons.groups_rounded,
        builder: (_) => FriendsListPage(),
      ),
      DrawerDestination(
        title: 'Preferences',
        icon: Icons.tune,
        builder: (_) => const PreferencesPage(),
      ),
      if (isAdmin)
        DrawerDestination(
          title: 'Admin',
          icon: Icons.admin_panel_settings,
          builder: (_) => const AdminPage(),
        ),
    ];
  }

  void _selectIndex(int newIndex) {
    final clamped = newIndex.clamp(0, _destinations.length - 1);
    setState(() => _index = clamped);
    Navigator.pop(context);
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dest = _destinations[_index];
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(dest.title),
        foregroundColor: Colors.white,
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1A237E),
                Color(0xFF3949AB),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        surfaceTintColor: Colors.transparent,
        shadowColor: colorScheme.shadow.withOpacity(0.12),
        actions: dest.actionsBuilder?.call(context),
      ),
      drawer: AppDrawer(
        selectedIndex: _index,
        onSelect: _selectIndex,
        destinations: _destinations,
        onLogout: _handleLogout,
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