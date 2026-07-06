import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileVisibilityManager extends ChangeNotifier {
  bool _showName = true;
  bool _showStatistics = true;

  bool get showName => _showName;
  bool get showStatistics => _showStatistics;

  ProfileVisibilityManager() {
    _loadVisibility();
  }

  Future<void> _loadVisibility() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _showName = prefs.getBool('profile_show_name') ?? true;
      _showStatistics = prefs.getBool('profile_show_statistics') ?? true;
      notifyListeners();
    } catch (e) {
      _showName = true;
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

  bool get isAllInfoHidden => !_showName;
}
