import 'package:flutter/material.dart';
import '../database/db.dart';
import '../firebase_database/firebase_db.dart';

/// ------------------------------
/// USER MODEL
/// ------------------------------
class AppUser {
  String name;
  String email;
  String role;

  AppUser({
    required this.name,
    required this.email,
    required this.role,
  });
}

/// ------------------------------
class UserStore {
  static List<AppUser> userList = [];
}

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

  /// ------------------------------
  /// FIXED: CORRECT DATA MAPPING
  /// ------------------------------
  Future<void> getUsers() async {
    UserStore.userList = [];
    // DB db = await DB.getReference();
    FirebaseDB db = FirebaseDB.getReference();

    List<Map<String, Object?>> users = await db.getUsers();

    for (Map<String, Object?> user in users) {
      UserStore.userList.add(
        AppUser(
          name: user["username"].toString(), // display name
          email: user["username"].toString(), // email = username
          role: user["isAdmin"].toString() == "1" ? "Admin" : "User",
        ),
      );
    }

    setState(() {});
  }

  /// ------------------------------
  /// ADD / EDIT USER (FIXED)
  /// ------------------------------
  void _addOrEditUser({AppUser? user, int? index}) {
    final nameController =
    TextEditingController(text: user != null ? user.name : "");
    final emailController =
    TextEditingController(text: user != null ? user.email : "");
    final passwordController = TextEditingController(); // ✅ NEW

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

              /// ✅ NEW PASSWORD FIELD
              if (user == null)
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration:
                  const InputDecoration(labelText: "Password"),
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
                /// ✅ FIXED ADD USER
                if (emailController.text.isNotEmpty &&
                    passwordController.text.isNotEmpty) {
                  await db.addUser(
                    emailController.text, // username/email
                    passwordController.text, // password
                    selectedRole == "Admin",
                  );

                  setState(() {
                    UserStore.userList.add(
                      AppUser(
                        name: nameController.text,
                        email: emailController.text,
                        role: selectedRole,
                      ),
                    );
                  });
                }
              } else {
                /// UPDATE ROLE ONLY
                await db.changeIsAdmin(
                  emailController.text,
                  selectedRole == "Admin",
                );

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

  /// ------------------------------
  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete User"),
        content: const Text("Are you sure you want to delete this user?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style:
            ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              DB db = await DB.getReference();

              await db.deleteUser(
                  UserStore.userList[index].email);

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

  /// ------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Users")),
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
                  margin: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
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
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
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