import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';

class SettingsScreen extends StatefulWidget {
  static const String routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: context.read<AppState>().userName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Changes the theme of the whole app'),
              secondary: Icon(
                  appState.isDarkMode ? Icons.dark_mode : Icons.light_mode),
              value: appState.isDarkMode,
              onChanged: (v) => context.read<AppState>().toggleTheme(v),
            ),
            const Divider(),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Profile name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              // Updates the Home Dashboard instantly on every keystroke.
              onChanged: (v) => context.read<AppState>().setUserName(v),
            ),
            const SizedBox(height: 8),
            Text('Current name: ${appState.userName}'),
          ],
        ),
      ),
    );
  }
}
