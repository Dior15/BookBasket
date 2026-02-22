import 'package:flutter/material.dart';

import 'manage_books.dart';
import 'manage_users.dart';
import 'reports.dart';
import 'system_settings.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: const [
          AdminCard(icon: Icons.book, title: "Manage Books"),
          AdminCard(icon: Icons.people, title: "Manage Users"),
          AdminCard(icon: Icons.analytics, title: "Reports"),
          AdminCard(icon: Icons.settings, title: "System Settings"),
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

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (title == "Manage Books") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ManageBooks(),
              ),
            );
          }
          else if (title == "Manage Users") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ManageUsers(),
              ),
            );
          }
          else if (title == "Reports") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const Reports(),
              ),
            );
          }
          else if (title == "System Settings") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SystemSettings(),
              ),
            );
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.deepPurple),
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