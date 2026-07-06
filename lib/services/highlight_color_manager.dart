import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HighlightColorManager extends ChangeNotifier {
  Color _highlightColor = Colors.purple;

  Color get highlightColor => _highlightColor;

  static const List<Map<String, dynamic>> availableColors = [
    {'key': 'colorPurple', 'color': Colors.purple},
    {'key': 'colorBlue', 'color': Colors.blue},
    {'key': 'colorRed', 'color': Colors.red},
    {'key': 'colorGreen', 'color': Colors.green},
    {'key': 'colorOrange', 'color': Colors.orange},
    {'key': 'colorPink', 'color': Colors.pink},
    {'key': 'colorTeal', 'color': Colors.teal},
    {'key': 'colorCyan', 'color': Colors.cyan},
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
        // Error case: silently continue
      }
    }
  }

  String getColorKey(Color color) {
    for (final colorMap in availableColors) {
      if (colorMap['color'] == color) {
        return colorMap['key'] as String;
      }
    }
    return 'colorCustom';
  }
}
