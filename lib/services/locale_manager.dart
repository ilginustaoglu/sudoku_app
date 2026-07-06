import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  system,
  english,
  turkish,
  german,
  french,
  spanish,
  italian,
  japanese,
  chinese,
  korean,
  dutch,
  russian,
}

class LocaleManager extends ChangeNotifier {
  static const String _prefKey = 'app_language_code';

  AppLanguage _language = AppLanguage.system;

  AppLanguage get language => _language;

  Locale? get locale {
    switch (_language) {
      case AppLanguage.system:
        return null;
      case AppLanguage.english:
        return const Locale('en');
      case AppLanguage.turkish:
        return const Locale('tr');
      case AppLanguage.german:
        return const Locale('de');
      case AppLanguage.french:
        return const Locale('fr');
      case AppLanguage.spanish:
        return const Locale('es');
      case AppLanguage.italian:
        return const Locale('it');
      case AppLanguage.japanese:
        return const Locale('ja');
      case AppLanguage.chinese:
        return const Locale('zh');
      case AppLanguage.korean:
        return const Locale('ko');
      case AppLanguage.dutch:
        return const Locale('nl');
      case AppLanguage.russian:
        return const Locale('ru');
    }
  }

  LocaleManager() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefKey);
      if (code != null) {
        _language = _fromCode(code);
      } else {
        // Migrate legacy int preference
        final index = prefs.getInt('app_language');
        if (index != null) {
          const legacy = [
            AppLanguage.system,
            AppLanguage.english,
            AppLanguage.turkish,
          ];
          if (index >= 0 && index < legacy.length) {
            _language = legacy[index];
          }
        }
      }
      notifyListeners();
    } catch (_) {
      _language = AppLanguage.system;
    }
  }

  static AppLanguage _fromCode(String code) {
    switch (code) {
      case 'en':
        return AppLanguage.english;
      case 'tr':
        return AppLanguage.turkish;
      case 'de':
        return AppLanguage.german;
      case 'fr':
        return AppLanguage.french;
      case 'es':
        return AppLanguage.spanish;
      case 'it':
        return AppLanguage.italian;
      case 'ja':
        return AppLanguage.japanese;
      case 'zh':
        return AppLanguage.chinese;
      case 'ko':
        return AppLanguage.korean;
      case 'nl':
        return AppLanguage.dutch;
      case 'ru':
        return AppLanguage.russian;
      default:
        return AppLanguage.system;
    }
  }

  String? get _languageCode {
    final loc = locale;
    return loc?.languageCode;
  }

  Future<void> setLanguage(AppLanguage language) async {
    _language = language;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      if (language == AppLanguage.system) {
        await prefs.remove(_prefKey);
      } else {
        await prefs.setString(_prefKey, _languageCode!);
      }
    } catch (_) {}
  }
}
