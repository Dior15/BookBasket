import 'package:flutter/material.dart';

class FriendsListPage extends StatelessWidget {
  const FriendsListPage({super.key});

  @override
  Widget build(BuildContext context) {

    final friends = [
      {"name": "Alex Chen", "book": "Atomic Habits"},
      {"name": "Sarah Kim", "book": "Clean Code"},
      {"name": "David Lee", "book": "Flutter in Action"},
      {"name": "Maria Garcia", "book": "The Pragmatic Programmer"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Friends"),
        backgroundColor: Colors.deepPurple,
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: friends.length,
        itemBuilder: (context, index) {

          final friend = friends[index];

          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),

            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.deepPurple,
                child: Icon(Icons.person, color: Colors.white),
              ),

              title: Text(
                friend["name"]!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              subtitle: Row(
                children: [
                  const Icon(Icons.menu_book, size: 16),
                  const SizedBox(width: 5),
                  Text("Reading: ${friend["book"]}"),
                ],
              ),

              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          );
        },
      ),
    );
  }
}