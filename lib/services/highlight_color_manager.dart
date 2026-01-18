import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HighlightColorManager extends ChangeNotifier {
  Color _highlightColor = Colors.purple; // Default: parlak mor

  Color get highlightColor => _highlightColor;

  // Kullanılabilir renkler
  static const List<Map<String, dynamic>> availableColors = [
    {'name': 'Purple', 'color': Colors.purple},
    {'name': 'Blue', 'color': Colors.blue},
    {'name': 'Red', 'color': Colors.red},
    {'name': 'Green', 'color': Colors.green},
    {'name': 'Orange', 'color': Colors.orange},
    {'name': 'Pink', 'color': Colors.pink},
    {'name': 'Teal', 'color': Colors.teal},
    {'name': 'Cyan', 'color': Colors.cyan},
  ];

  HighlightColorManager() {
    _loadColor();
  }

  Future<void> _loadColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final colorValue = prefs.getInt('highlight_color');
      if (colorValue != null) {
        _highlightColor = Color(colorValue);
      }
      notifyListeners();
    } catch (e) {
      // Hata durumunda default rengi kullan
      _highlightColor = Colors.purple;
    }
  }

  Future<void> setHighlightColor(Color color) async {
    if (_highlightColor != color) {
      _highlightColor = color;
      notifyListeners();
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('highlight_color', color.value);
      } catch (e) {
        // Hata durumunda sessizce devam et
      }
    }
  }

  String getColorName(Color color) {
    for (var colorMap in availableColors) {
      if (colorMap['color'] == color) {
        return colorMap['name'];
      }
    }
    return 'Custom';
  }
}

