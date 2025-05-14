import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _emailSummary = true;
  bool _darkMode = false;

  void _toggleEmailSummary(bool value) {
    setState(() {
      _emailSummary = value;
      // TODO: Call API or local save logic
    });
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      _darkMode = value;
      // TODO: Trigger dark mode logic (theme provider, etc.)
    });
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Clear tokens / navigate to login screen
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Logged out")),
              );
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            title: const Text("Email Summary"),
            value: _emailSummary,
            onChanged: _toggleEmailSummary,
          ),
          SwitchListTile(
            title: const Text("Dark Mode"),
            value: _darkMode,
            onChanged: _toggleDarkMode,
          ),
          const Divider(),
          ListTile(
            title: const Text("Account Info"),
            trailing: const Icon(Icons.person),
            onTap: () {
              // TODO: Navigate to account info screen
            },
          ),
          ListTile(
            title: const Text("Change Password"),
            trailing: const Icon(Icons.lock),
            onTap: () {
              // TODO: Open change password flow
            },
          ),
          const Divider(),
          ListTile(
            title: const Text("Logout"),
            trailing: const Icon(Icons.exit_to_app),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
