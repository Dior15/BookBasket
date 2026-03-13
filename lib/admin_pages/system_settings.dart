import 'package:flutter/material.dart';

class SystemSettings extends StatefulWidget {
  const SystemSettings({super.key});

  @override
  State<SystemSettings> createState() => _SystemSettingsState();
}

class _SystemSettingsState extends State<SystemSettings> {

  // ------------------------------
  // ACCOUNT SETTINGS
  // ------------------------------
  bool allowRegistration = true;
  bool requireEmailVerification = false;

  // ------------------------------
  // BOOK SETTINGS
  // ------------------------------
  bool allowEpubUploads = true;
  String maxFileSize = "10 MB";

  // ------------------------------
  // BASKET SETTINGS
  // ------------------------------
  bool allowMultipleBooks = true;
  bool clearBasketOnLogout = false;

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFF3949AB),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _groupCard({required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(children: children),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("System Settings"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
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
            child: const Text(
              'System Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),

          /// ------------------------------
          /// ACCOUNT SETTINGS
          /// ------------------------------
          _sectionTitle("Account Settings"),
          _groupCard(
            children: [
              SwitchListTile(
                title: const Text("Allow New User Registration"),
                value: allowRegistration,
                onChanged: (value) {
                  setState(() {
                    allowRegistration = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text("Require Email Verification"),
                value: requireEmailVerification,
                onChanged: (value) {
                  setState(() {
                    requireEmailVerification = value;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 8),

          /// ------------------------------
          /// BOOK SETTINGS
          /// ------------------------------
          _sectionTitle("Book Settings"),
          _groupCard(
            children: [
              SwitchListTile(
                title: const Text("Allow EPUB Uploads"),
                value: allowEpubUploads,
                onChanged: (value) {
                  setState(() {
                    allowEpubUploads = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: maxFileSize,
                decoration: const InputDecoration(
                  labelText: "Maximum File Size",
                ),
                items: const [
                  DropdownMenuItem(value: "5 MB", child: Text("5 MB")),
                  DropdownMenuItem(value: "10 MB", child: Text("10 MB")),
                  DropdownMenuItem(value: "20 MB", child: Text("20 MB")),
                ],
                onChanged: (value) {
                  setState(() {
                    maxFileSize = value!;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 8),

          /// ------------------------------
          /// BASKET SETTINGS
          /// ------------------------------
          _sectionTitle("Basket Settings"),
          _groupCard(
            children: [
              SwitchListTile(
                title: const Text("Allow Multiple Books in Basket"),
                value: allowMultipleBooks,
                onChanged: (value) {
                  setState(() {
                    allowMultipleBooks = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text("Clear Basket On Logout"),
                value: clearBasketOnLogout,
                onChanged: (value) {
                  setState(() {
                    clearBasketOnLogout = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}