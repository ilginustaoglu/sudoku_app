import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundManager extends ChangeNotifier {
  bool _soundEnabled = true;

  bool get soundEnabled => _soundEnabled;

  SoundManager() {
    _loadSoundSetting();
  }

  Future<void> _loadSoundSetting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool('sound_enabled') ?? true; // Default: enabled
      notifyListeners();
    } catch (e) {
      // Error case: use default value
      _soundEnabled = true;
    }
  }

  Future<void> setSoundEnabled(bool enabled) async {
    if (_soundEnabled != enabled) {
      _soundEnabled = enabled;
      notifyListeners();
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('sound_enabled', enabled);
      } catch (e) {
        // Error case: silently continue
      }
    }
  }
}

