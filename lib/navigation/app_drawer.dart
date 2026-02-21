import 'package:flutter/material.dart';

class DrawerDestination {
  final String title;
  final IconData icon;
  final WidgetBuilder builder;

  /// Optional extra widgets placed in the shell's AppBar actions row.
  final List<Widget> Function(BuildContext context)? actionsBuilder;

  const DrawerDestination({
    required this.title,
    required this.icon,
    required this.builder,
    this.actionsBuilder,
  });
}

class AppDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<DrawerDestination> destinations;

  /// Called when the user taps the Logout tile at the bottom.
  final VoidCallback onLogout;

  const AppDrawer({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.destinations,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blueGrey),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'BookBasket',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (var i = 0; i < destinations.length; i++)
                  ListTile(
                    leading: Icon(destinations[i].icon),
                    title: Text(destinations[i].title),
                    selected: i == selectedIndex,
                    onTap: () => onSelect(i),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: onLogout,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
