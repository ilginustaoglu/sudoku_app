import 'package:shared_preferences/shared_preferences.dart';

class OnboardingManager {
  OnboardingManager._();

  static const String _homeGuidePrefKey = 'pending_home_onboarding';

  static Future<void> scheduleHomeGuide() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_homeGuidePrefKey, true);
  }

  static Future<bool> shouldShowHomeGuide() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_homeGuidePrefKey) ?? false;
  }

  static Future<void> completeHomeGuide() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_homeGuidePrefKey, false);
  }
}
