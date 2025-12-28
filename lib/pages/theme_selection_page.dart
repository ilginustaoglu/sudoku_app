import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_manager.dart';

class ThemeSelectionPage extends StatelessWidget {
  const ThemeSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Selection'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Select a theme',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_auto),
            title: const Text('System'),
            subtitle: const Text('Use your device theme'),
            trailing: themeManager.themeMode == ThemeMode.system
                ? const Icon(Icons.check, color: Color(0xFF2E7D32)) // Koyu yeşil
                : null,
            onTap: () {
              themeManager.setThemeMode(ThemeMode.system);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.brightness_high),
            title: const Text('Light'),
            subtitle: const Text('Use light theme'),
            trailing: themeManager.themeMode == ThemeMode.light
                ? const Icon(Icons.check, color: Color(0xFF2E7D32)) // Koyu yeşil
                : null,
            onTap: () {
              themeManager.setThemeMode(ThemeMode.light);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.brightness_low),
            title: const Text('Dark'),
            subtitle: const Text('Use dark theme'),
            trailing: themeManager.themeMode == ThemeMode.dark
                ? const Icon(Icons.check, color: Color(0xFF2E7D32)) // Koyu yeşil
                : null,
            onTap: () {
              themeManager.setThemeMode(ThemeMode.dark);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

