import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum StatisticsVisibility {
  onlyMe,
  friends,
  everyone,
}

class StatisticsVisibilityManager extends ChangeNotifier {
  StatisticsVisibility _visibility = StatisticsVisibility.onlyMe;

  StatisticsVisibility get visibility => _visibility;

  StatisticsVisibilityManager() {
    _loadVisibility();
  }

  Future<void> _loadVisibility() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final visibilityIndex = prefs.getInt('statistics_visibility') ?? 0;
      _visibility = StatisticsVisibility.values[visibilityIndex];
      notifyListeners();
    } catch (e) {
      _visibility = StatisticsVisibility.onlyMe;
    }
  }

  Future<void> setVisibility(StatisticsVisibility visibility) async {
    if (_visibility != visibility) {
      _visibility = visibility;
      notifyListeners();
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('statistics_visibility', visibility.index);
      } catch (e) {
        // Error case: silently continue
      }
    }
  }

  String getVisibilityText(StatisticsVisibility visibility) {
    switch (visibility) {
      case StatisticsVisibility.onlyMe:
        return 'Only Me';
      case StatisticsVisibility.friends:
        return 'My Friends';
      case StatisticsVisibility.everyone:
        return 'Everyone';
    }
  }
}
