import 'package:flutter/material.dart';

import 'admin_pages/manage_books.dart';
import 'admin_pages/manage_users.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Manage content, users',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              children: const [
                AdminCard(icon: Icons.book_rounded, title: "Manage Books"),
                AdminCard(icon: Icons.people_alt_rounded, title: "Manage Users"),

              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminCard extends StatelessWidget {
  final IconData icon;
  final String title;

  const AdminCard({
    super.key,
    required this.icon,
    required this.title,
  });

  void _handleTap(BuildContext context) {
    if (title == "Manage Books") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ManageBooks(),
        ),
      );
    } else if (title == "Manage Users") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ManageUsers(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF3949AB);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.6),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _handleTap(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 30, color: accent),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}