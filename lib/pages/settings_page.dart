import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../models/user_profile.dart';
import '../services/theme_manager.dart';
import '../services/sound_manager.dart';
import '../services/highlight_color_manager.dart';
import '../services/profile_manager.dart';
import '../services/statistics_visibility_manager.dart';
import '../services/profile_visibility_manager.dart';

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
          Consumer<StatisticsVisibilityManager>(
            builder: (context, visibilityManager, child) {
              return ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('Statistics Visibility'),
                subtitle: Text(visibilityManager.getVisibilityText(visibilityManager.visibility)),
                trailing: PopupMenuButton<StatisticsVisibility>(
                  icon: const Icon(Icons.chevron_right),
                  onSelected: (StatisticsVisibility visibility) {
                    visibilityManager.setVisibility(visibility);
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<StatisticsVisibility>(
                      value: StatisticsVisibility.onlyMe,
                      child: Row(
                        children: [
                          const Icon(Icons.lock),
                          const SizedBox(width: 8),
                          const Text('Only Me'),
                          if (visibilityManager.visibility == StatisticsVisibility.onlyMe) ...[
                            const Spacer(),
                            const Icon(Icons.check, color: Color(0xFF2E7D32)),
                          ],
                        ],
                      ),
                    ),
                    PopupMenuItem<StatisticsVisibility>(
                      value: StatisticsVisibility.friends,
                      child: Row(
                        children: [
                          const Icon(Icons.people),
                          const SizedBox(width: 8),
                          const Text('My Friends'),
                          if (visibilityManager.visibility == StatisticsVisibility.friends) ...[
                            const Spacer(),
                            const Icon(Icons.check, color: Color(0xFF2E7D32)),
                          ],
                        ],
                      ),
                    ),
                    PopupMenuItem<StatisticsVisibility>(
                      value: StatisticsVisibility.everyone,
                      child: Row(
                        children: [
                          const Icon(Icons.public),
                          const SizedBox(width: 8),
                          const Text('Everyone'),
                          if (visibilityManager.visibility == StatisticsVisibility.everyone) ...[
                            const Spacer(),
                            const Icon(Icons.check, color: Color(0xFF2E7D32)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          // Profil Görünürlük Ayarları
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Profile Visibility',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Consumer<ProfileVisibilityManager>(
            builder: (context, visibilityManager, child) {
              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Show Name'),
                    subtitle: const Text('Display your name on profile'),
                    trailing: Switch(
                      value: visibilityManager.showName,
                      onChanged: (value) {
                        visibilityManager.setShowName(value);
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('Show Email'),
                    subtitle: const Text('Display your email on profile'),
                    trailing: Switch(
                      value: visibilityManager.showEmail,
                      onChanged: (value) {
                        visibilityManager.setShowEmail(value);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          const Divider(),
          // Display Name Ayarı
          Consumer<ProfileManager>(
            builder: (context, profileManager, child) {
              final profile = profileManager.currentProfile;
              if (profile == null || profileManager.isGuestMode) {
                return const SizedBox.shrink();
              }
              
              return ListTile(
                leading: const Icon(Icons.badge),
                title: const Text('Display Name'),
                subtitle: Text(profile.displayName ?? 'Not set'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showDisplayNameDialog(context, profileManager, profile),
              );
            },
          ),
          const Divider(),
          // Profil ve Cover Image Renk Ayarları
          Consumer<ProfileManager>(
            builder: (context, profileManager, child) {
              final profile = profileManager.currentProfile;
              if (profile == null || profileManager.isGuestMode) {
                return const SizedBox.shrink();
              }
              
              final List<Color> colorOptions = [
                Colors.blue,
                Colors.green,
                Colors.orange,
                Colors.purple,
                Colors.red,
                Colors.teal,
                Colors.pink,
                Colors.indigo,
                Colors.amber,
                Colors.cyan,
                Colors.brown,
                Colors.grey,
              ];
              
              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.account_circle),
                    title: const Text('Profile Color'),
                    subtitle: const Text('Choose profile avatar color'),
                    trailing: PopupMenuButton<Color>(
                      icon: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: profile.avatarColor != null
                              ? Color(profile.avatarColor!)
                              : Colors.grey.shade300,
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                      ),
                      onSelected: (Color color) async {
                        final updatedProfile = profile.copyWith(avatarColor: color.value);
                        await profileManager.updateProfile(updatedProfile);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile color updated successfully'),
                            ),
                          );
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return colorOptions.map((color) {
                          final isSelected = profile.avatarColor == color.value;
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
                                Text(_getColorName(color)),
                                if (isSelected) ...[
                                  const Spacer(),
                                  const Icon(Icons.check, color: Color(0xFF2E7D32)),
                                ],
                              ],
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.image),
                    title: const Text('Cover Background'),
                    subtitle: const Text('Choose cover background'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showCoverSelectionDialog(context, profileManager, profile, colorOptions),
                  ),
                  const Divider(),
                ],
              );
            },
          ),
          Consumer<ProfileManager>(
            builder: (context, profileManager, child) {
              return ListTile(
                leading: const Icon(Icons.storage),
                title: const Text('Database Info'),
                subtitle: FutureBuilder<Map<String, dynamic>>(
                  future: profileManager.getDatabaseStats(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final stats = snapshot.data!;
                      return Text(
                        '${stats['profilesCount']} profiles, ${stats['scoresCount']} scores',
                      );
                    }
                    return const Text('Loading...');
                  },
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  try {
                    final stats = await profileManager.getDatabaseStats();
                    final dbPath = stats['databasePath'];
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (BuildContext dialogContext) {
                          return AlertDialog(
                            title: const Text('Database Information'),
                            content: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Database Name:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const Text('sudoku_profiles.db'),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Statistics:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text('Profiles: ${stats['profilesCount']}'),
                                  Text('Game Scores: ${stats['scoresCount']}'),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Database Path:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SelectableText(dbPath),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'To open in TablePlus:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text('1. Open TablePlus'),
                                  const Text('2. Click "Create a new connection"'),
                                  const Text('3. Select "SQLite"'),
                                  const Text('4. Paste the path above'),
                                  const Text('5. Click "Connect"'),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: dbPath));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Database path copied to clipboard'),
                                    ),
                                  );
                                },
                                child: const Text('Copy Path'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text('Close'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
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

  String _getColorName(Color color) {
    if (color == Colors.blue) return 'Blue';
    if (color == Colors.green) return 'Green';
    if (color == Colors.orange) return 'Orange';
    if (color == Colors.purple) return 'Purple';
    if (color == Colors.red) return 'Red';
    if (color == Colors.teal) return 'Teal';
    if (color == Colors.pink) return 'Pink';
    if (color == Colors.indigo) return 'Indigo';
    if (color == Colors.amber) return 'Amber';
    if (color == Colors.cyan) return 'Cyan';
    if (color == Colors.brown) return 'Brown';
    if (color == Colors.grey) return 'Grey';
    return 'Unknown';
  }

  Future<void> _showDisplayNameDialog(BuildContext context, ProfileManager profileManager, profile) async {
    final TextEditingController controller = TextEditingController(text: profile.displayName ?? '');
    
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Set Display Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Display Name',
              hintText: 'Enter your display name',
              border: OutlineInputBorder(),
            ),
            maxLength: 30,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final displayName = controller.text.trim();
                final updatedProfile = profile.copyWith(
                  displayName: displayName.isEmpty ? null : displayName,
                );
                await profileManager.updateProfile(updatedProfile);
                if (context.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Display name updated successfully'),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    
    controller.dispose();
  }

  Future<void> _showCoverSelectionDialog(
    BuildContext context,
    ProfileManager profileManager,
    profile,
    List<Color> colorOptions,
  ) async {
    // Default cover görselleri
    final List<String> defaultCovers = [
      'assets/images/default_covers/_ (2).jpeg',
      'assets/images/default_covers/_ (3).jpeg',
      'assets/images/default_covers/_ (4).jpeg',
      'assets/images/default_covers/_ (5).jpeg',
      'assets/images/default_covers/_ (6).jpeg',
      'assets/images/default_covers/_ (7).jpeg',
      'assets/images/default_covers/_ (8).jpeg',
      'assets/images/default_covers/_ (9).jpeg',
      'assets/images/default_covers/_ (10).jpeg',
      'assets/images/default_covers/_ (11).jpeg',
      'assets/images/default_covers/_Seasonal Wallpapers & Festive Backgrounds_.jpeg',
      'assets/images/default_covers/background aesthetic.jpeg',
      'assets/images/default_covers/panda wallpaper.jpeg',
      'assets/images/default_covers/Sudoku Iphone Wallpaper.jpeg',
      'assets/images/default_covers/Vintage Rose IPhone Wallpaper, HD Background With Handwriting.jpeg',
      'assets/images/default_covers/wow wallpaper🤍.jpeg',
      'assets/images/default_covers/Фон для сторис Инстаграм, задний фон, бежевая красивая винтажная крафт бумага.jpeg',
      'assets/images/default_covers/아이폰 단색 배경화면 _ 카톡 배경화면.jpeg',
    ];

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          child: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Select Cover Background',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        const TabBar(
                          tabs: [
                            Tab(text: 'Colors'),
                            Tab(text: 'Default Covers'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              // Renkler sekmesi
                              GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: colorOptions.length,
                                itemBuilder: (context, index) {
                                  final color = colorOptions[index];
                                  final isSelected = profile.coverImageColor == color.value &&
                                      (profile.coverImagePath == null || profile.coverImagePath!.isEmpty);
                                  
                                  return GestureDetector(
                                    onTap: () async {
                                      final updatedProfile = profile.copyWith(
                                        coverImageColor: color.value,
                                        coverImagePath: null, // Renk seçildiğinde görseli kaldır
                                      );
                                      await profileManager.updateProfile(updatedProfile);
                                      if (context.mounted) {
                                        Navigator.pop(dialogContext);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Cover color updated successfully'),
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? Colors.black : Colors.grey.shade400,
                                          width: isSelected ? 3 : 1,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check, color: Colors.white, size: 30)
                                          : null,
                                    ),
                                  );
                                },
                              ),
                              // Default cover görselleri sekmesi
                              GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: defaultCovers.length,
                                itemBuilder: (context, index) {
                                  final coverPath = defaultCovers[index];
                                  final isSelected = profile.coverImagePath == coverPath;
                                  
                                  return GestureDetector(
                                    onTap: () async {
                                      final updatedProfile = profile.copyWith(
                                        coverImagePath: coverPath,
                                        coverImageColor: null, // Görsel seçildiğinde rengi kaldır
                                      );
                                      await profileManager.updateProfile(updatedProfile);
                                      if (context.mounted) {
                                        Navigator.pop(dialogContext);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Cover image updated successfully'),
                                          ),
                                        );
                                      }
                                    },
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.asset(
                                            coverPath,
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey.shade300,
                                                child: const Icon(Icons.error),
                                              );
                                            },
                                          ),
                                        ),
                                        if (isSelected)
                                          Positioned.fill(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.3),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 3,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 40,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

