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
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
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
        padding: const EdgeInsets.all(16),
        children: [

          /// ------------------------------
          /// ACCOUNT SETTINGS
          /// ------------------------------
          _sectionTitle("Account Settings"),

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

          const Divider(),

          /// ------------------------------
          /// BOOK SETTINGS
          /// ------------------------------
          _sectionTitle("Book Settings"),

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
              border: OutlineInputBorder(),
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

          const Divider(),

          /// ------------------------------
          /// BASKET SETTINGS
          /// ------------------------------
          _sectionTitle("Basket Settings"),

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
    );
  }
}