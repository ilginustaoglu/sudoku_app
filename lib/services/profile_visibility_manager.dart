import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileVisibilityManager extends ChangeNotifier {
  bool _showName = true;
  bool _showEmail = true;
  bool _showStatistics = true; // İstatistikler her zaman gösterilebilir (ayrı bir ayar var)

  bool get showName => _showName;
  bool get showEmail => _showEmail;
  bool get showStatistics => _showStatistics;

  ProfileVisibilityManager() {
    _loadVisibility();
  }

  Future<void> _loadVisibility() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _showName = prefs.getBool('profile_show_name') ?? true;
      _showEmail = prefs.getBool('profile_show_email') ?? true;
      _showStatistics = prefs.getBool('profile_show_statistics') ?? true;
      notifyListeners();
    } catch (e) {
      _showName = true;
      _showEmail = true;
      _showStatistics = true;
    }
  }

  Future<void> setShowName(bool show) async {
    if (_showName != show) {
      _showName = show;
      notifyListeners();
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('profile_show_name', show);
      } catch (e) {
        // Error case: silently continue
      }
    }
  }

  Future<void> setShowEmail(bool show) async {
    if (_showEmail != show) {
      _showEmail = show;
      notifyListeners();
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('profile_show_email', show);
      } catch (e) {
        // Error case: silently continue
      }
    }
  }

  Future<void> setShowStatistics(bool show) async {
    if (_showStatistics != show) {
      _showStatistics = show;
      notifyListeners();
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('profile_show_statistics', show);
      } catch (e) {
        // Error case: silently continue
      }
    }
  }

  // Tüm bilgiler gizli mi kontrol et (istatistik hariç)
  bool get isAllInfoHidden {
    return !_showName && !_showEmail;
  }
}
