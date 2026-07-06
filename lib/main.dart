import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_config.dart';
import 'services/game_state_manager.dart';
import 'services/theme_manager.dart';
import 'services/sound_manager.dart';
import 'services/highlight_color_manager.dart';
import 'services/profile_manager.dart';
import 'services/statistics_visibility_manager.dart';
import 'services/profile_visibility_manager.dart';
import 'services/locale_manager.dart';
import 'l10n/app_localizations.dart';
import 'pages/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.isSupabaseConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
  }

  runApp(const SudokuApp());
}

class SudokuApp extends StatelessWidget {
  const SudokuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeManager()),
        ChangeNotifierProvider(create: (_) => LocaleManager()),
        ChangeNotifierProvider(create: (_) => GameStateManager()),
        ChangeNotifierProvider(create: (_) => SoundManager()),
        ChangeNotifierProvider(create: (_) => HighlightColorManager()),
        ChangeNotifierProvider(create: (_) => ProfileManager()),
        ChangeNotifierProvider(create: (_) => StatisticsVisibilityManager()),
        ChangeNotifierProvider(create: (_) => ProfileVisibilityManager()),
      ],
      child: Consumer2<ThemeManager, LocaleManager>(
        builder: (context, themeManager, localeManager, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Pandoku',
            locale: localeManager.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            localeResolutionCallback: (deviceLocale, supportedLocales) {
              if (localeManager.locale != null) {
                return localeManager.locale!;
              }
              if (deviceLocale != null) {
                for (final supported in supportedLocales) {
                  if (supported.languageCode == deviceLocale.languageCode) {
                    return supported;
                  }
                }
              }
              return const Locale('en');
            },
            theme: ThemeData(
              primaryColor: const Color(0xFF2E7D32), // Koyu yeşil
              primarySwatch: MaterialColor(
                0xFF2E7D32,
                <int, Color>{
                  50: const Color(0xFFE8F5E9),
                  100: const Color(0xFFC8E6C9),
                  200: const Color(0xFFA5D6A7),
                  300: const Color(0xFF81C784),
                  400: const Color(0xFF66BB6A),
                  500: const Color(0xFF2E7D32),
                  600: const Color(0xFF2E7D32),
                  700: const Color(0xFF1B5E20),
                  800: const Color(0xFF1B5E20),
                  900: const Color(0xFF1B5E20),
                },
              ),
              useMaterial3: true,
              brightness: Brightness.light,
              scaffoldBackgroundColor: Colors.white,
              colorScheme: ColorScheme.light(
                primary: const Color(0xFF2E7D32), // Koyu yeşil
                secondary: const Color(0xFF6F4E37), // Kahve rengi
                surface: Colors.white,
                background: Colors.white,
              ),
            ),
            darkTheme: ThemeData(
              primaryColor: const Color(0xFF2E7D32), // Koyu yeşil
              primarySwatch: MaterialColor(
                0xFF2E7D32,
                <int, Color>{
                  50: const Color(0xFFE8F5E9),
                  100: const Color(0xFFC8E6C9),
                  200: const Color(0xFFA5D6A7),
                  300: const Color(0xFF81C784),
                  400: const Color(0xFF66BB6A),
                  500: const Color(0xFF2E7D32),
                  600: const Color(0xFF2E7D32),
                  700: const Color(0xFF1B5E20),
                  800: const Color(0xFF1B5E20),
                  900: const Color(0xFF1B5E20),
                },
              ),
              useMaterial3: true,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: Colors.grey[900],
              colorScheme: ColorScheme.dark(
                primary: const Color(0xFF66BB6A), // Açık yeşil (dark mode için)
                secondary: const Color(0xFF8B6F47), // Açık kahve (dark mode için)
                surface: Colors.grey[800]!,
                background: Colors.grey[900]!,
              ),
            ),
            themeMode: themeManager.themeMode,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
