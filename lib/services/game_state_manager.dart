import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sudoku_game.dart';

class GameStateManager extends ChangeNotifier {
  SudokuGame? _currentGame;
  bool _isLoading = true;

  bool get hasOngoingGame => !_isLoading && _currentGame != null && !_currentGame!.isCompleted;
  SudokuGame? get currentGame => _currentGame;
  bool get isLoading => _isLoading;

  GameStateManager() {
    _initialize();
  }

  // Başlangıç yükleme
  Future<void> _initialize() async {
    await _loadGame();
    _isLoading = false;
    notifyListeners();
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
    _saveGame(); // async çağrı, await edilmiyor ama sorun değil
    notifyListeners();
  }

  // Oyunu tamamlandı olarak işaretle
  void completeGame() {
    if (_currentGame != null) {
      _currentGame!.isCompleted = true;
      _saveGame(); // async çağrı, await edilmiyor ama sorun değil
      notifyListeners();
    }
  }

  // Devam eden oyunu temizle
  void clearGame() {
    _currentGame = null;
    _saveGame(); // async çağrı, await edilmiyor ama sorun değil
    notifyListeners();
  }
}

