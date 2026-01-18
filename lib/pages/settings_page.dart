import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_manager.dart';
import '../services/sound_manager.dart';
import '../services/highlight_color_manager.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'App Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: Text(_getThemeModeText(themeManager.themeMode)),
            trailing: PopupMenuButton<ThemeMode>(
              icon: const Icon(Icons.chevron_right),
              onSelected: (ThemeMode mode) {
                themeManager.setThemeMode(mode);
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<ThemeMode>(
                  value: ThemeMode.system,
                  child: Row(
                    children: [
                      Icon(Icons.brightness_auto),
                      SizedBox(width: 8),
                      Text('System'),
                    ],
                  ),
                ),
                const PopupMenuItem<ThemeMode>(
                  value: ThemeMode.light,
                  child: Row(
                    children: [
                      Icon(Icons.brightness_high),
                      SizedBox(width: 8),
                      Text('Light'),
                    ],
                  ),
                ),
                const PopupMenuItem<ThemeMode>(
                  value: ThemeMode.dark,
                  child: Row(
                    children: [
                      Icon(Icons.brightness_low),
                      SizedBox(width: 8),
                      Text('Dark'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Consumer<SoundManager>(
            builder: (context, soundManager, child) {
              return ListTile(
                leading: const Icon(Icons.volume_up),
                title: const Text('Sound'),
                subtitle: const Text('Enable/disable sound effects'),
                trailing: Switch(
                  value: soundManager.soundEnabled,
                  onChanged: (value) {
                    soundManager.setSoundEnabled(value);
                  },
                ),
              );
            },
          ),
          const Divider(),
          Consumer<HighlightColorManager>(
            builder: (context, highlightColorManager, child) {
              return ListTile(
                leading: Icon(
                  Icons.colorize,
                  color: highlightColorManager.highlightColor,
                ),
                title: const Text('Highlight Color'),
                subtitle: Text(
                  'Selected: ${highlightColorManager.getColorName(highlightColorManager.highlightColor)}',
                ),
                trailing: PopupMenuButton<Color>(
                  icon: Icon(
                    Icons.chevron_right,
                    color: highlightColorManager.highlightColor,
                  ),
                  onSelected: (Color color) {
                    highlightColorManager.setHighlightColor(color);
                  },
                  itemBuilder: (BuildContext context) {
                    return HighlightColorManager.availableColors.map((colorMap) {
                      final color = colorMap['color'] as Color;
                      final name = colorMap['name'] as String;
                      final isSelected = highlightColorManager.highlightColor == color;
                      
                      return PopupMenuItem<Color>(
                        value: color,
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey.shade400,
                                  width: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(name),
                            if (isSelected) ...[
                              const Spacer(),
                              Icon(
                                Icons.check,
                                color: color,
                                size: 20,
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList();
                  },
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            subtitle: const Text('App information'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Pandoku',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.grid_4x4, size: 48),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System theme';
      case ThemeMode.light:
        return 'Light theme';
      case ThemeMode.dark:
        return 'Dark theme';
    }
  }
}

