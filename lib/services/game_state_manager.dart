import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sudoku_game.dart';
import 'statistics_manager.dart';
import 'daily_game_manager.dart';

class GameStateManager extends ChangeNotifier {
  SudokuGame? _currentGame;
  bool _isLoading = true;

  bool get hasOngoingGame => !_isLoading && _currentGame != null && !_currentGame!.isCompleted;
  SudokuGame? get currentGame => _currentGame;
  bool get isLoading => _isLoading;
  
  // Lazy initialization - ilk kullanımda başlat
  void ensureInitialized() {
    if (_isLoading && !_isInitializing) {
      _initialize();
    }
  }

  bool _isInitializing = false;

  GameStateManager() {
    // Tamamen lazy initialization - sadece gerektiğinde başlat
    // UI render'ı hiç bloklamaz
    // Initialization'ı hemen başlat ama await etme (non-blocking)
    // Sadece bir kez başlatmak için kontrol et
    if (_isLoading && !_isInitializing) {
      Future.microtask(() {
        ensureInitialized();
      });
    }
  }

  // Başlangıç yükleme
  Future<void> _initialize() async {
    if (_isInitializing) return;
    _isInitializing = true;
    
    await _loadGame();
    _isLoading = false;
    notifyListeners();
    
    _isInitializing = false;
  }

  // Oyunu yükle
  Future<void> _loadGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gameJson = prefs.getString('current_game');
      
      if (gameJson != null) {
        final gameMap = json.decode(gameJson) as Map<String, dynamic>;
        _currentGame = SudokuGame.fromJson(gameMap);
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
      _currentGame = null;
    }
  }

  // Oyunu kaydet
  Future<void> _saveGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentGame != null) {
        final gameJson = json.encode(_currentGame!.toJson());
        await prefs.setString('current_game', gameJson);
      } else {
        await prefs.remove('current_game');
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  // Yeni oyun başlat
  void startNewGame(SudokuGame game) {
    _currentGame = game;
    _saveGame(); // async çağrı, await edilmiyor ama sorun değil
    notifyListeners();
  }

  // Mevcut oyunu güncelle
  void updateGame(SudokuGame game) {
    _currentGame = game;
    _saveGame();

    _persistDailyGame(game);
    notifyListeners();
  }

  // Oyunu tamamlandı olarak işaretle
  void completeGame() {
    if (_currentGame != null) {
      _currentGame!.isCompleted = true;
      _saveGame();

      final statisticsManager = StatisticsManager();
      final now = DateTime.now();
      statisticsManager.recordCompletedGame(now);

      _persistDailyGame(_currentGame!);

      notifyListeners();
    }
  }

  void _persistDailyGame(SudokuGame game) {
    final puzzleDate = game.dailyPuzzleDate;
    if (puzzleDate == null) return;
    DailyGameManager().saveDailyGame(puzzleDate, game);
  }

  // Devam eden oyunu temizle
  void clearGame() {
    _currentGame = null;
    _saveGame(); // async çağrı, await edilmiyor ama sorun değil
    notifyListeners();
  }
}

