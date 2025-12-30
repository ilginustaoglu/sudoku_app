import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sudoku_game.dart';
import 'sudoku_generator.dart';
import 'dart:math';

class DailyGameManager {
  static final DailyGameManager _instance = DailyGameManager._internal();
  factory DailyGameManager() => _instance;
  DailyGameManager._internal();

  // Günlük oyunu al (yoksa oluştur)
  Future<SudokuGame> getDailyGame(DateTime date) async {
    // Gelecek tarihler için oyun oluşturma
    final today = DateTime.now();
    final selected = DateTime(date.year, date.month, date.day);
    final todayDate = DateTime(today.year, today.month, today.day);
    if (selected.isAfter(todayDate)) {
      throw Exception('Cannot create game for future dates');
    }
    
    final dateKey = _getDateKey(date);
    final prefs = await SharedPreferences.getInstance();
    final gameJson = prefs.getString('daily_game_$dateKey');
    
    if (gameJson != null) {
      try {
        final gameMap = json.decode(gameJson) as Map<String, dynamic>;
        return SudokuGame.fromJson(gameMap);
      } catch (e) {
        // Hata durumunda yeni oyun oluştur
      }
    }
    
    // Yeni günlük oyun oluştur
    final difficulties = ['Easy', 'Medium', 'Hard'];
    final random = Random(date.millisecondsSinceEpoch);
    final difficulty = difficulties[random.nextInt(difficulties.length)];
    
    final game = SudokuGenerator.generateNewGame(difficulty: difficulty);
    await saveDailyGame(date, game);
    
    return game;
  }

  // Günlük oyunu kaydet
  Future<void> saveDailyGame(DateTime date, SudokuGame game) async {
    final dateKey = _getDateKey(date);
    final prefs = await SharedPreferences.getInstance();
    final gameJson = json.encode(game.toJson());
    await prefs.setString('daily_game_$dateKey', gameJson);
  }

  // Tarih anahtarı oluştur (YYYY-MM-DD formatında)
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Belirli bir tarihin oyununu kontrol et (var mı?)
  Future<bool> hasDailyGame(DateTime date) async {
    final dateKey = _getDateKey(date);
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('daily_game_$dateKey');
  }
}

