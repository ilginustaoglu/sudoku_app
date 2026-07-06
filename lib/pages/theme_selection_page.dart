import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/theme_manager.dart';

class ThemeSelectionPage extends StatelessWidget {
  const ThemeSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.themeSelection),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              l10n.selectTheme,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_auto),
            title: Text(l10n.themeSystem),
            subtitle: Text(l10n.themeSystemSubtitle),
            trailing: themeManager.themeMode == ThemeMode.system
                ? const Icon(Icons.check, color: Color(0xFF2E7D32))
                : null,
            onTap: () {
              themeManager.setThemeMode(ThemeMode.system);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.brightness_high),
            title: Text(l10n.themeLight),
            subtitle: Text(l10n.themeLightSubtitle),
            trailing: themeManager.themeMode == ThemeMode.light
                ? const Icon(Icons.check, color: Color(0xFF2E7D32))
                : null,
            onTap: () {
              themeManager.setThemeMode(ThemeMode.light);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.brightness_low),
            title: Text(l10n.themeDark),
            subtitle: Text(l10n.themeDarkSubtitle),
            trailing: themeManager.themeMode == ThemeMode.dark
                ? const Icon(Icons.check, color: Color(0xFF2E7D32))
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
