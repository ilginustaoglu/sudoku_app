import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/locale_manager.dart';
import '../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              l10n.appSettings,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: Text(l10n.theme),
            subtitle: Text(l10n.themeModeLabel(themeManager.themeMode)),
            trailing: PopupMenuButton<ThemeMode>(
              icon: const Icon(Icons.chevron_right),
              onSelected: (ThemeMode mode) {
                themeManager.setThemeMode(mode);
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<ThemeMode>(
                  value: ThemeMode.system,
                  child: Row(
                    children: [
                      const Icon(Icons.brightness_auto),
                      const SizedBox(width: 8),
                      Text(l10n.themeSystem),
                    ],
                  ),
                ),
                PopupMenuItem<ThemeMode>(
                  value: ThemeMode.light,
                  child: Row(
                    children: [
                      const Icon(Icons.brightness_high),
                      const SizedBox(width: 8),
                      Text(l10n.themeLight),
                    ],
                  ),
                ),
                PopupMenuItem<ThemeMode>(
                  value: ThemeMode.dark,
                  child: Row(
                    children: [
                      const Icon(Icons.brightness_low),
                      const SizedBox(width: 8),
                      Text(l10n.themeDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Consumer<LocaleManager>(
            builder: (context, localeManager, child) {
              return ListTile(
                leading: const Icon(Icons.language),
                title: Text(l10n.language),
                subtitle: Text(l10n.languageLabel(localeManager.language)),
                trailing: PopupMenuButton<AppLanguage>(
                  icon: const Icon(Icons.chevron_right),
                  onSelected: localeManager.setLanguage,
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem(
                      value: AppLanguage.system,
                      child: Text(l10n.langSystem),
                    ),
                    PopupMenuItem(
                      value: AppLanguage.english,
                      child: Text(l10n.langEnglish),
                    ),
                    PopupMenuItem(
                      value: AppLanguage.turkish,
                      child: Text(l10n.langTurkish),
                    ),
                    PopupMenuItem(
                      value: AppLanguage.german,
                      child: Text(l10n.langGerman),
                    ),
                    PopupMenuItem(
                      value: AppLanguage.french,
                      child: Text(l10n.langFrench),
                    ),
                    PopupMenuItem(
                      value: AppLanguage.spanish,
                      child: Text(l10n.langSpanish),
                    ),
                    PopupMenuItem(
                      value: AppLanguage.italian,
                      child: Text(l10n.langItalian),
                    ),
                    PopupMenuItem(
                      value: AppLanguage.japanese,
                      child: Text(l10n.langJapanese),
                    ),
                    PopupMenuItem(
                      value: AppLanguage.chinese,
                      child: Text(l10n.langChinese),
                    ),
                    PopupMenuItem(
                      value: AppLanguage.korean,
                      child: Text(l10n.langKorean),
                    ),
                    PopupMenuItem(
                      value: AppLanguage.dutch,
                      child: Text(l10n.langDutch),
                    ),
                    PopupMenuItem(
                      value: AppLanguage.russian,
                      child: Text(l10n.langRussian),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          Consumer<SoundManager>(
            builder: (context, soundManager, child) {
              return ListTile(
                leading: const Icon(Icons.volume_up),
                title: Text(l10n.sound),
                subtitle: Text(l10n.soundSubtitle),
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
                title: Text(l10n.highlightColor),
                subtitle: Text(
                  l10n.selectedColor(
                    l10n.localizedColorName(
                      highlightColorManager.getColorKey(
                        highlightColorManager.highlightColor,
                      ),
                    ),
                  ),
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
                      final nameKey = colorMap['key'] as String;
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
                            Text(l10n.localizedColorName(nameKey)),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              l10n.profileVisibility,
              style: const TextStyle(
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
                    title: Text(l10n.showName),
                    subtitle: Text(l10n.showNameSubtitle),
                    trailing: Switch(
                      value: visibilityManager.showName,
                      onChanged: visibilityManager.setShowName,
                    ),
                  ),
                ],
              );
            },
          ),
          Consumer<StatisticsVisibilityManager>(
            builder: (context, visibilityManager, child) {
              return ListTile(
                leading: const Icon(Icons.bar_chart),
                title: Text(l10n.statisticsVisibility),
                subtitle: Text(
                  l10n.visibilityLabel(visibilityManager.visibility),
                ),
                trailing: PopupMenuButton<StatisticsVisibility>(
                  icon: const Icon(Icons.chevron_right),
                  onSelected: visibilityManager.setVisibility,
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<StatisticsVisibility>(
                      value: StatisticsVisibility.onlyMe,
                      child: Row(
                        children: [
                          const Icon(Icons.lock),
                          const SizedBox(width: 8),
                          Text(l10n.visibilityOnlyMe),
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
                          Text(l10n.visibilityFriends),
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
                          Text(l10n.visibilityEveryone),
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
          // Display Name Ayarı
          Consumer<ProfileManager>(
            builder: (context, profileManager, child) {
              final profile = profileManager.currentProfile;
              if (profile == null || profileManager.isGuestMode) {
                return const SizedBox.shrink();
              }
              
              return ListTile(
                leading: const Icon(Icons.badge),
                title: Text(l10n.displayName),
                subtitle: Text(l10n.displayNamePersonalSubtitle),
                trailing: Text(
                  profile.displayName ?? l10n.displayNameNotSet,
                  style: TextStyle(
                    color: profile.displayName != null
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                ),
                onTap: () => _showDisplayNameDialog(context, profileManager, profile),
              );
            },
          ),
          const Divider(),
          // Profil rengi ayarı
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
                    title: Text(l10n.profileColor),
                    subtitle: Text(l10n.profileColorSubtitle),
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
                            SnackBar(
                              content: Text(l10n.profileColorUpdated),
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
                                Text(l10n.localizedColor(color)),
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
                  const Divider(),
                ],
              );
            },
          ),
          Consumer<ProfileManager>(
            builder: (context, profileManager, child) {
              final profile = profileManager.currentProfile;
              if (profile == null || profileManager.isGuestMode) {
                return const SizedBox.shrink();
              }

              return Column(
                children: [
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.delete_forever,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: Text(
                      l10n.deleteAccount,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    subtitle: Text(l10n.deleteAccountSubtitle),
                    onTap: () => _confirmDeleteAccount(
                      context,
                      profileManager,
                      profile.id,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showDisplayNameDialog(BuildContext context, ProfileManager profileManager, profile) async {
    final l10n = AppLocalizations.of(context);
    final TextEditingController controller = TextEditingController(text: profile.displayName ?? '');
    
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.setDisplayName),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: l10n.displayName,
              hintText: l10n.displayNameHint,
              border: const OutlineInputBorder(),
            ),
            maxLength: 30,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
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
                    SnackBar(
                      content: Text(l10n.displayNameUpdated),
                    ),
                  );
                }
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
    
    controller.dispose();
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    ProfileManager profileManager,
    String profileId,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.deleteAccountConfirmTitle),
          content: Text(l10n.deleteAccountConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(l10n.deleteAccount),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await profileManager.deleteProfile(profileId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deleteAccountSuccess)),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deleteAccountFailed)),
      );
    }
  }

}

