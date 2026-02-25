import 'package:flutter/material.dart';

/// ------------------------------
/// USER MODEL
/// ------------------------------
class AppUser {
  String name;
  String email;
  String role; // "User" or "Admin"

  AppUser({
    required this.name,
    required this.email,
    required this.role,
  });
}

/// ------------------------------
/// SHARED USER STORE (UI ONLY)
/// ------------------------------
class UserStore {
  static List<AppUser> users = [
    AppUser(name: "Book Basket User", email: "user@bookbasket.com", role: "User"),
    AppUser(name: "Book Basket Admin User", email: "admin@bookbasket.com", role: "Admin"),
  ];
}

/// ------------------------------
/// MANAGE USERS PAGE
/// ------------------------------
class ManageUsers extends StatefulWidget {
  const ManageUsers({super.key});

  @override
  State<ManageUsers> createState() => _ManageUsersState();
}

class _ManageUsersState extends State<ManageUsers> {

  void _addOrEditUser({AppUser? user, int? index}) {
    final nameController =
    TextEditingController(text: user != null ? user.name : "");
    final emailController =
    TextEditingController(text: user != null ? user.email : "");
    String selectedRole = user != null ? user.role : "User";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(user == null ? "Add User" : "Edit User"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRole,
                items: const [
                  DropdownMenuItem(value: "User", child: Text("User")),
                  DropdownMenuItem(value: "Admin", child: Text("Admin")),
                ],
                onChanged: (value) {
                  selectedRole = value!;
                },
                decoration: const InputDecoration(labelText: "Role"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (user == null) {
                setState(() {
                  UserStore.users.add(
                    AppUser(
                      name: nameController.text,
                      email: emailController.text,
                      role: selectedRole,
                    ),
                  );
                });
              } else {
                setState(() {
                  UserStore.users[index!] = AppUser(
                    name: nameController.text,
                    email: emailController.text,
                    role: selectedRole,
                  );
                });
              }

              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete User"),
        content: const Text("Are you sure you want to delete this user?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                UserStore.users.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    return role == "Admin" ? Colors.red : Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Users"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Total Users: ${UserStore.users.length}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: UserStore.users.length,
              itemBuilder: (context, index) {
                final user = UserStore.users[index];

                return Card(
                  margin:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(user.name),
                    subtitle: Text(user.email),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _roleColor(user.role),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.role,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () =>
                              _addOrEditUser(user: user, index: index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _confirmDelete(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditUser(),
        child: const Icon(Icons.add),
      ),
    );
  }
}