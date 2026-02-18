import 'package:shared_preferences/shared_preferences.dart';

class StatisticsManager {
  static final StatisticsManager _instance = StatisticsManager._internal();
  factory StatisticsManager() => _instance;
  StatisticsManager._internal();

  // Tamamlanan oyunu kaydet
  Future<void> recordCompletedGame(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = _getDateKey(date);
    
    // Günlük tamamlanan oyun sayısını artır
    final dailyKey = 'completed_$dateKey';
    final currentCount = prefs.getInt(dailyKey) ?? 0;
    await prefs.setInt(dailyKey, currentCount + 1);
  }

  // Yıllık tamamlanan oyun sayısı
  Future<int> getYearlyCompleted(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final year = date.year;
    int total = 0;
    
    for (int month = 1; month <= 12; month++) {
      for (int day = 1; day <= 31; day++) {
        final dateKey = '${year}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
        total += prefs.getInt('completed_$dateKey') ?? 0;
      }
    }
    
    return total;
  }

  // Aylık tamamlanan oyun sayısı
  Future<int> getMonthlyCompleted(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final year = date.year;
    final month = date.month;
    int total = 0;
    
    // Ayın gün sayısını hesapla
    final daysInMonth = DateTime(year, month + 1, 0).day;
    
    for (int day = 1; day <= daysInMonth; day++) {
      final dateKey = '${year}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      total += prefs.getInt('completed_$dateKey') ?? 0;
    }
    
    return total;
  }

  // Haftalık tamamlanan oyun sayısı
  Future<int> getWeeklyCompleted(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    // Haftanın başlangıcını bul (Pazartesi)
    final weekStart = date.subtract(Duration(days: date.weekday - 1));
    int total = 0;
    
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final dateKey = _getDateKey(day);
      total += prefs.getInt('completed_$dateKey') ?? 0;
    }
    
    return total;
  }

  // Haftanın her günü için tamamlanan oyun sayıları
  Future<List<int>> getWeeklyDailyCompleted(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    // Haftanın başlangıcını bul (Pazartesi)
    final weekStart = date.subtract(Duration(days: date.weekday - 1));
    List<int> dailyCounts = [];
    
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final dateKey = _getDateKey(day);
      dailyCounts.add(prefs.getInt('completed_$dateKey') ?? 0);
    }
    
    return dailyCounts;
  }

  // Tarih anahtarı oluştur (YYYY-MM-DD formatında)
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

