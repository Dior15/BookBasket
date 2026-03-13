import 'package:flutter/material.dart';
import '../database/db.dart';

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
  static List<AppUser> userList = [
    // AppUser(name: "Book Basket User", email: "user@bookbasket.com", role: "User"),
    // AppUser(name: "Book Basket Admin User", email: "admin@bookbasket.com", role: "Admin"),
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
  static const _accent = Color(0xFF3949AB);

  @override
  void initState() {
    super.initState();
    getUsers();
  }

  Future<void> getUsers() async {
    UserStore.userList = [];
    DB db = await DB.getReference();
    List<Map<String, Object?>> users = await db.getUsers();
    for (Map<String, Object?> user in users) {
      UserStore.userList.add(AppUser(name: user["username"].toString(), email: user["password"].toString(), role: user["isAdmin"].toString() == "1" ? "Admin" : "User"));
    }
    setState(() {});
  }

  void _addOrEditUser({AppUser? user, int? index}) {
    final nameController =
    TextEditingController(text: user != null ? user.name : "");
    final emailController =
    TextEditingController(text: user != null ? user.email : "");
    String selectedRole = user != null ? user.role : "User";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            onPressed: () async {
              DB db = await DB.getReference();
              if (user == null) {
                // Add
                db.addUser(emailController.text, "123", selectedRole == "Admin"); // THERE'S NO PASSWORD FIELD IN THE FORM, SO SETTING A DEFAULT PASSWORD OF 123
                setState(() {
                  UserStore.userList.add(
                    AppUser(
                      name: nameController.text,
                      email: emailController.text,
                      role: selectedRole,
                    ),
                  );
                });
              } else {
                // Update
                db.changeIsAdmin(emailController.text, selectedRole == "Admin");
                setState(() {
                  UserStore.userList[index!] = AppUser(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete User"),
        content: const Text("Are you sure you want to delete this user?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              DB db = await DB.getReference();
              db.deleteUser(UserStore.userList.elementAt(index).email);
              setState(() {
                UserStore.userList.removeAt(index);
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
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Text(
                "Total Users: ${UserStore.userList.length}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: UserStore.userList.length,
              itemBuilder: (context, index) {
                final user = UserStore.userList[index];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.person_rounded, color: _accent),
                    ),
                    title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700)),
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
                          icon: const Icon(Icons.edit_rounded),
                          onPressed: () => _addOrEditUser(user: user, index: index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
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
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}