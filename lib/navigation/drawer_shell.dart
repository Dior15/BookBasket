import 'dart:async';

import 'package:bookbasket/map/map.dart';
import 'package:flutter/material.dart';

import '../admin.dart';
import '../auth_service.dart';
import '../basket.dart';
import '../catalog.dart';
import '../firebase_database/firebase_db.dart';
import '../friends_list.dart';
import '../login_page.dart';
import '../preferences_page.dart';
import '../search.dart';
import 'app_drawer.dart';

class DrawerShell extends StatefulWidget {
  /// When [isAdmin] is true the Admin panel destination is included.
  final bool isAdmin;

  const DrawerShell({super.key, this.isAdmin = false});

  @override
  State<DrawerShell> createState() => _DrawerShellState();
}

class _DrawerShellState extends State<DrawerShell> {
  late int _index;

  final FirebaseDB _db = FirebaseDB.getReference();
  StreamSubscription<Map<String, dynamic>>? _friendInfoSubscription;

  int _incomingRequestCount = 0;

  @override
  void initState() {
    super.initState();
    _index = 0;
    _listenForFriendRequests();
  }

  @override
  void dispose() {
    _friendInfoSubscription?.cancel();
    super.dispose();
  }

  Future<void> _listenForFriendRequests() async {
    final email = await AuthService.getEmail();
    if (email == null) return;

    final currentUser = email.trim().toLowerCase();

    _friendInfoSubscription =
        _db.getFriendInfoStream(currentUser).listen((friendData) {
          if (!mounted) return;

          final incoming = List<String>.from(
            friendData['incomingRequests'] ?? const [],
          );

          setState(() {
            _incomingRequestCount = incoming.length;
          });
        });
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
      ),
      DrawerDestination(
        title: 'Reading Map',
        icon: Icons.map,
        builder: (_) => MapPage(),
      ),
      DrawerDestination(
        title: 'Friends',
        icon: Icons.groups_rounded,
        builder: (_) => const FriendsListPage(),
        badgeCount: _incomingRequestCount,
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
    final destinations = _buildDestinations(widget.isAdmin);
    final clamped = newIndex.clamp(0, destinations.length - 1);
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
    final destinations = _buildDestinations(widget.isAdmin);
    final dest = destinations[_index];
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
        destinations: destinations,
        onLogout: _handleLogout,
      ),
      body: IndexedStack(
        index: _index,
        children: destinations
            .map((destination) => Builder(builder: destination.builder))
            .toList(),
      ),
    );
  }
}