import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import '../services/game_state_manager.dart';
import '../services/profile_manager.dart';
import '../services/sound_manager.dart';
import '../services/highlight_color_manager.dart';
import '../services/profile_visibility_manager.dart';
import '../models/sudoku_game.dart';
import '../models/game_score.dart';
import '../services/sudoku_generator.dart';

class GamePage extends StatefulWidget {
  final GameStateManager gameStateManager;

  const GamePage({super.key, required this.gameStateManager});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  late SudokuGame game;
  int selectedRow = -1;
  int selectedCol = -1;
  Timer? _timer;
  DateTime? _timerStartTime; // Timer'ın bu oturumda başladığı zaman
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool get hasErrorLimit => game.difficulty == 'Medium' || game.difficulty == 'Hard';
  bool _isNoteMode = false; // Not alma modu
  
  // Tamamlanan satır/sütun animasyonları için
  Map<int, AnimationController> _rowAnimations = {};
  Map<int, AnimationController> _colAnimations = {};
  Map<int, AnimationController> _blockAnimations = {}; // Blok animasyonları (blockIndex -> controller)
  Set<int> _completedRows = {};
  Set<int> _completedCols = {};
  Set<int> _completedBlocks = {}; // Tamamlanan 3x3 bloklar (0-8)

  @override
  void initState() {
    super.initState();
    game = widget.gameStateManager.currentGame!;
    // Timer'ı bir sonraki frame'de başlat (build tamamlandıktan sonra)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTimer();
    });
  }

  @override
  void dispose() {
    _stopTimerAndSave();
    _audioPlayer.dispose();
    // Animasyon controller'ları temizle
    for (var controller in _rowAnimations.values) {
      controller.dispose();
    }
    for (var controller in _colAnimations.values) {
      controller.dispose();
    }
    for (var controller in _blockAnimations.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    // Timer başlatıldığında şimdiki zamanı kaydet
    _timerStartTime = DateTime.now();
    
    // Timer'ı optimize et - sadece gerektiğinde rebuild yap
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !game.isCompleted) {
        // Sadece timer değerini güncelle - minimal rebuild
        setState(() {});
      } else {
        timer.cancel();
      }
    });
  }

  void _stopTimerAndSave() {
    _timer?.cancel();
    if (_timerStartTime != null) {
      // Bu oturumda geçen süreyi hesapla ve ekle
      final sessionElapsed = DateTime.now().difference(_timerStartTime!).inSeconds;
      game.elapsedSeconds += sessionElapsed;
      game.startTime = DateTime.now(); // Son durdurulma zamanını kaydet
      widget.gameStateManager.updateGame(game);
    }
  }

  Duration get _elapsedTime {
    if (game.isCompleted) {
      // Oyun tamamlandıysa sadece kaydedilmiş süreyi göster
      return Duration(seconds: game.elapsedSeconds);
    }
    
    // Kaydedilmiş süre + bu oturumda geçen süre
    final sessionElapsed = _timerStartTime != null 
        ? DateTime.now().difference(_timerStartTime!).inSeconds 
        : 0;
    return Duration(seconds: game.elapsedSeconds + sessionElapsed);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  void selectCell(int row, int col) {
    // Tüm hücreler seçilebilir (verilen sayılara da tıklanabilir)
    setState(() {
      selectedRow = row;
      selectedCol = col;
    });
  }

  // Seçili hücredeki sayıyla aynı sayıya sahip tüm hücreleri bul
  bool _isSameValueCell(int row, int col) {
    if (selectedRow == -1 || selectedCol == -1) return false;
    if (game.currentBoard[row][col] == 0) return false;
    if (game.currentBoard[selectedRow][selectedCol] == 0) return false;
    
    // Aynı sayıya sahip mi kontrol et (hem baştan verilen hem de kullanıcı tarafından girilen sayılar için)
    return game.currentBoard[row][col] == game.currentBoard[selectedRow][selectedCol];
  }

  // Bir sayının tahtada kaç kez olduğunu say
  int _countNumberInBoard(int number) {
    int count = 0;
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (game.currentBoard[i][j] == number) {
          count++;
        }
      }
    }
    return count;
  }

  // Bir sayı tamamen doldurulmuş mu? (9 adet)
  bool _isNumberComplete(int number) {
    return _countNumberInBoard(number) >= 9;
  }

  // Bir satır tamamlanmış mı kontrol et
  bool _isRowComplete(int row) {
    Set<int> numbers = {};
    for (int col = 0; col < 9; col++) {
      int value = game.currentBoard[row][col];
      if (value == 0) return false;
      if (numbers.contains(value)) return false; // Tekrar eden sayı
      numbers.add(value);
    }
    return numbers.length == 9;
  }

  // Bir sütun tamamlanmış mı kontrol et
  bool _isColComplete(int col) {
    Set<int> numbers = {};
    for (int row = 0; row < 9; row++) {
      int value = game.currentBoard[row][col];
      if (value == 0) return false;
      if (numbers.contains(value)) return false; // Tekrar eden sayı
      numbers.add(value);
    }
    return numbers.length == 9;
  }

  // Bir 3x3 blok tamamlanmış mı kontrol et
  bool _isBlockComplete(int blockIndex) {
    // Blok index'inden başlangıç pozisyonunu hesapla
    int startRow = (blockIndex ~/ 3) * 3;
    int startCol = (blockIndex % 3) * 3;
    
    Set<int> numbers = {};
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        int value = game.currentBoard[startRow + i][startCol + j];
        if (value == 0) return false;
        if (numbers.contains(value)) return false; // Tekrar eden sayı
        numbers.add(value);
      }
    }
    return numbers.length == 9;
  }

  // Tamamlanan satır/sütun/blokları kontrol et ve animasyon başlat
  void _checkCompletedRowsAndCols() {
    // Satırları kontrol et
    for (int row = 0; row < 9; row++) {
      if (_isRowComplete(row) && !_completedRows.contains(row)) {
        _completedRows.add(row);
        _playColumnCompletionSound();
        _startRowAnimation(row);
      }
    }
    
    // Sütunları kontrol et
    for (int col = 0; col < 9; col++) {
      if (_isColComplete(col) && !_completedCols.contains(col)) {
        _completedCols.add(col);
        _playColumnCompletionSound();
        _startColAnimation(col);
      }
    }
    
    // Blokları kontrol et (0-8 arası 9 blok)
    for (int blockIndex = 0; blockIndex < 9; blockIndex++) {
      if (_isBlockComplete(blockIndex) && !_completedBlocks.contains(blockIndex)) {
        _completedBlocks.add(blockIndex);
        _playColumnCompletionSound();
        _startBlockAnimation(blockIndex);
      }
    }
  }

  // Satır animasyonu başlat
  void _startRowAnimation(int row) {
    if (!_rowAnimations.containsKey(row)) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1800),
      );
      _rowAnimations[row] = controller;
    }
    // Reset ve başlat (smooth animasyon için)
    if (_rowAnimations[row]!.isAnimating) {
      _rowAnimations[row]!.stop();
    }
    _rowAnimations[row]!.reset();
    _rowAnimations[row]!.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && _rowAnimations.containsKey(row)) {
          _rowAnimations[row]!.reverse();
        }
      });
    });
  }

  // Sütun animasyonu başlat
  void _startColAnimation(int col) {
    if (!_colAnimations.containsKey(col)) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1800),
      );
      _colAnimations[col] = controller;
    }
    // Reset ve başlat (smooth animasyon için)
    if (_colAnimations[col]!.isAnimating) {
      _colAnimations[col]!.stop();
    }
    _colAnimations[col]!.reset();
    _colAnimations[col]!.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && _colAnimations.containsKey(col)) {
          _colAnimations[col]!.reverse();
        }
      });
    });
  }

  // Blok animasyonu başlat (3x3 blok için)
  void _startBlockAnimation(int blockIndex) {
    if (!_blockAnimations.containsKey(blockIndex)) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      );
      _blockAnimations[blockIndex] = controller;
    }
    // Reset ve başlat
    if (_blockAnimations[blockIndex]!.isAnimating) {
      _blockAnimations[blockIndex]!.stop();
    }
    _blockAnimations[blockIndex]!.reset();
    _blockAnimations[blockIndex]!.forward();
  }
  
  // Bir hücrenin hangi blokta olduğunu hesapla (0-8)
  int _getBlockIndex(int row, int col) {
    return (row ~/ 3) * 3 + (col ~/ 3);
  }

  void setNumber(int number) {
    if (selectedRow == -1 || selectedCol == -1) return;
    if (game.isGiven[selectedRow][selectedCol]) return; // Verilen sayılar değiştirilemez
    if (game.isCompleted) return; // Oyun tamamlandıysa hamle yapılamaz

    setState(() {
      if (_isNoteMode) {
        // Not alma modu: sayıyı not olarak ekle/çıkar
        if (game.currentBoard[selectedRow][selectedCol] == 0) {
          // Sadece boş hücrelerde not alınabilir
          if (game.notes[selectedRow][selectedCol].contains(number)) {
            game.notes[selectedRow][selectedCol].remove(number);
          } else {
            game.notes[selectedRow][selectedCol].add(number);
          }
        }
        widget.gameStateManager.updateGame(game);
        return;
      }

      // Normal mod: sayıyı direkt yaz
      // Çözümle karşılaştır
      bool isCorrect = number == game.solution[selectedRow][selectedCol];
      int previousValue = game.currentBoard[selectedRow][selectedCol];
      
      // Notları temizle (sayı girildiğinde)
      if (number != 0) {
        game.notes[selectedRow][selectedCol].clear();
      }
      
      // Sadece yeni bir sayı girildiğinde skor güncelle (önceki değerden farklıysa)
      if (number != 0 && previousValue != number) {
        if (isCorrect) {
          // Doğru sayı: +10 puan
          game.score += 10;
        } else {
          // Yanlış sayı: -10 puan (skor negatif olamaz)
          game.score = (game.score - 10).clamp(0, double.infinity).toInt();
        }
      }
      
      game.currentBoard[selectedRow][selectedCol] = number;
      
      // Error check (only for Medium and Hard levels)
      // Sadece yeni bir yanlış sayı girildiğinde hata say (önceki değerden farklıysa)
      if (hasErrorLimit && !isCorrect && number != 0 && previousValue != number) {
        game.errorCount++;
        
        // Yanlış cevap sesi çal
        _playWrongAnswerSound();
        
        // 3 hata yapıldıysa oyun kaybedildi
        if (game.errorCount >= 3) {
          game.isCompleted = true;
          _stopTimerAndSave();
          widget.gameStateManager.completeGame();
          _showGameOverDialog();
          return;
        }
      }
      
      // Tamamlanan satır/sütunları kontrol et
      _checkCompletedRowsAndCols();
      
      // Oyun tamamlandı mı kontrol et
      if (SudokuGenerator.isGameComplete(game.currentBoard, game.solution)) {
        game.isCompleted = true;
        _stopTimerAndSave();
        widget.gameStateManager.completeGame();
        
        // Skorları kaydet (eğer profil varsa)
        _saveScore();
        
        _playCongratulationsSound();
        _showCompletionDialog();
      } else {
        // Oyunu kaydet
        widget.gameStateManager.updateGame(game);
      }
    });
  }

  void clearCell() {
    if (selectedRow == -1 || selectedCol == -1) return;
    if (game.isGiven[selectedRow][selectedCol]) return;
    if (game.isCompleted) return;

    setState(() {
      game.currentBoard[selectedRow][selectedCol] = 0;
      game.notes[selectedRow][selectedCol].clear();
      widget.gameStateManager.updateGame(game);
    });
  }

  Widget _buildScoreContainer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Score',
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF2E7D32),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            game.score.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1B5E20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContainer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Text(
            'Error',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              return Icon(
                index < game.errorCount ? Icons.close : Icons.close_outlined,
                color: index < game.errorCount ? Colors.red : Colors.grey.shade300,
                size: 24,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitNumberButtons() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: ElevatedButton(
            onPressed: () => setState(() => _isNoteMode = !_isNoteMode),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              minimumSize: const Size(50, 50),
              shape: const CircleBorder(),
            ),
            child: Icon(
              _isNoteMode ? Icons.edit : Icons.edit_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (i) => _buildNumberButton(i + 1)),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ...List.generate(4, (i) => _buildNumberButton(i + 6)),
                  ElevatedButton(
                    onPressed: clearCell,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade300,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      minimumSize: const Size(50, 50),
                    ),
                    child: const Icon(Icons.delete, size: 24),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildLandscapeNumberButton(int number) {
    final isDisabled = _isNumberComplete(number);
    return ElevatedButton(
      onPressed: isDisabled ? null : () => setNumber(number),
      style: ElevatedButton.styleFrom(
        backgroundColor: _isNoteMode
            ? (isDisabled ? Colors.grey : Colors.white)
            : (isDisabled ? Colors.grey : const Color(0xFF2E7D32)),
        foregroundColor: _isNoteMode
            ? (isDisabled ? Colors.grey.shade400 : Colors.black)
            : Colors.white,
        padding: const EdgeInsets.all(12),
        minimumSize: const Size(44, 44),
        shape: const CircleBorder(),
      ),
      child: Text(
        number.toString(),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _isNoteMode
              ? (isDisabled ? Colors.grey.shade400 : Colors.black)
              : (isDisabled ? Colors.grey.shade400 : Colors.white),
        ),
      ),
    );
  }

  Widget _buildNumberButton(int number) {
    final isDisabled = _isNumberComplete(number);
    return ElevatedButton(
      onPressed: isDisabled ? null : () => setNumber(number),
      style: ElevatedButton.styleFrom(
        backgroundColor: _isNoteMode
            ? (isDisabled ? Colors.grey : Colors.white)
            : (isDisabled ? Colors.grey : const Color(0xFF2E7D32)),
        foregroundColor: _isNoteMode
            ? (isDisabled ? Colors.grey.shade400 : Colors.black)
            : Colors.white,
        padding: const EdgeInsets.all(16),
        minimumSize: const Size(50, 50),
      ),
      child: Text(
        number.toString(),
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: _isNoteMode
              ? (isDisabled ? Colors.grey.shade400 : Colors.black)
              : (isDisabled ? Colors.grey.shade400 : Colors.white),
        ),
      ),
    );
  }

  Widget _buildSudokuGrid(HighlightColorManager highlightColorManager) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 9,
      ),
      itemCount: 81,
      itemBuilder: (context, index) => _buildGridCell(context, index, highlightColorManager),
    );
  }

  Widget _buildGridCell(BuildContext context, int index, HighlightColorManager highlightColorManager) {
    int row = index ~/ 9;
    int col = index % 9;
    bool isSelected = row == selectedRow && col == selectedCol;
    bool isGiven = game.isGiven[row][col];
    int value = game.currentBoard[row][col];
    bool isSameValue = _isSameValueCell(row, col);
    bool isValid = value == 0 ||
        SudokuGenerator.isValidMove(game.currentBoard, row, col, value);
    bool isCorrect = value == 0 || value == game.solution[row][col];
    bool hasError = !isGiven && value != 0 && (
        hasErrorLimit ? !isCorrect : !isValid);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlightColor = highlightColorManager.highlightColor;

    Color textColor;
    if (isGiven) {
      textColor = isSameValue ? highlightColor : (isDark ? Colors.white : Colors.black);
    } else {
      textColor = isSameValue ? highlightColor : (isDark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32));
    }

    double rowAnimationValue = _rowAnimations.containsKey(row) ? _rowAnimations[row]!.value : 0.0;
    double colAnimationValue = _colAnimations.containsKey(col) ? _colAnimations[col]!.value : 0.0;
    double maxAnimationValue = rowAnimationValue > colAnimationValue ? rowAnimationValue : colAnimationValue;

    Color backgroundColor;
    if (maxAnimationValue > 0) {
      final greenColor = const Color(0xFF2E7D32);
      final baseColor = isGiven
          ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
          : (isDark ? Colors.grey.shade900 : Colors.white);
      backgroundColor = Color.lerp(baseColor, greenColor.withOpacity(0.6), maxAnimationValue)!;
    } else if (isSelected) {
      backgroundColor = hasError
          ? Colors.pink.withOpacity(0.4)
          : (isDark ? const Color(0xFF2E7D32).withOpacity(0.3) : const Color(0xFF2E7D32).withOpacity(0.2));
    } else if (hasError) {
      backgroundColor = Colors.pink.withOpacity(0.3);
    } else if (isGiven) {
      backgroundColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    } else {
      backgroundColor = isDark ? Colors.grey.shade900 : Colors.white;
    }

    final blockIndex = _getBlockIndex(row, col);
    final blockController = _blockAnimations[blockIndex];
    List<Listenable> animationListeners = [];
    if (_rowAnimations.containsKey(row)) animationListeners.add(_rowAnimations[row]!);
    if (_colAnimations.containsKey(col)) animationListeners.add(_colAnimations[col]!);
    if (blockController != null) animationListeners.add(blockController);

    return GestureDetector(
      onTap: () => selectCell(row, col),
      child: AnimatedBuilder(
        animation: animationListeners.isEmpty ? Listenable.merge([]) : Listenable.merge(animationListeners),
        builder: (context, child) {
          double rowAnimValue = _rowAnimations.containsKey(row)
              ? Curves.easeOutCubic.transform(_rowAnimations[row]!.value) : 0.0;
          double colAnimValue = _colAnimations.containsKey(col)
              ? Curves.easeOutCubic.transform(_colAnimations[col]!.value) : 0.0;
          double blockAnimValue = blockController != null
              ? Curves.easeOutCubic.transform(blockController.value) : 0.0;
          double rowColScale = 1.0;
          if (rowAnimValue > 0 || colAnimValue > 0) {
            final maxRowColValue = rowAnimValue > colAnimValue ? rowAnimValue : colAnimValue;
            rowColScale = 0.85 + (maxRowColValue * 0.15);
          }
          double blockScale = blockAnimValue > 0 ? 0.85 + (blockAnimValue * 0.15) : 1.0;
          final finalScale = rowColScale > blockScale ? rowColScale : blockScale;
          final maxAnimValue = rowAnimValue > colAnimValue ? rowAnimValue : colAnimValue;
          final maxAllAnimValue = maxAnimValue > blockAnimValue ? maxAnimValue : blockAnimValue;

          Color animBackgroundColor;
          if (maxAllAnimValue > 0) {
            final greenColor = const Color(0xFF2E7D32);
            final baseColor = isGiven
                ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
                : (isDark ? Colors.grey.shade900 : Colors.white);
            animBackgroundColor = Color.lerp(
                baseColor, greenColor.withOpacity(0.4 * (1 - maxAllAnimValue)), maxAllAnimValue)!;
          } else {
            animBackgroundColor = backgroundColor;
          }

          return Transform.scale(
            scale: finalScale,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    width: row % 3 == 0 ? 2.5 : 0.5,
                    color: maxAllAnimValue > 0
                        ? const Color(0xFF2E7D32).withOpacity(0.3 + maxAllAnimValue * 0.5)
                        : Colors.grey.shade600,
                  ),
                  left: BorderSide(
                    width: col % 3 == 0 ? 2.5 : 0.5,
                    color: maxAllAnimValue > 0
                        ? const Color(0xFF2E7D32).withOpacity(0.3 + maxAllAnimValue * 0.5)
                        : Colors.grey.shade600,
                  ),
                  right: BorderSide(
                    width: col == 8 ? 2.5 : 0.5,
                    color: maxAllAnimValue > 0
                        ? const Color(0xFF2E7D32).withOpacity(0.3 + maxAllAnimValue * 0.5)
                        : Colors.grey.shade600,
                  ),
                  bottom: BorderSide(
                    width: row == 8 ? 2.5 : 0.5,
                    color: maxAllAnimValue > 0
                        ? const Color(0xFF2E7D32).withOpacity(0.3 + maxAllAnimValue * 0.5)
                        : Colors.grey.shade600,
                  ),
                ),
                color: animBackgroundColor,
              ),
              child: Stack(
                children: [
                  if (value != 0)
                    Center(
                      child: Text(
                        value.toString(),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor),
                      ),
                    ),
                  if (value == 0 && game.notes[row][col].isNotEmpty)
                    ...game.notes[row][col].map((noteNumber) {
                      Alignment alignment;
                      switch (noteNumber) {
                        case 1: alignment = Alignment.topLeft; break;
                        case 2: alignment = Alignment.topCenter; break;
                        case 3: alignment = Alignment.topRight; break;
                        case 4: alignment = Alignment.centerLeft; break;
                        case 5: alignment = Alignment.center; break;
                        case 6: alignment = Alignment.centerRight; break;
                        case 7: alignment = Alignment.bottomLeft; break;
                        case 8: alignment = Alignment.bottomCenter; break;
                        case 9: alignment = Alignment.bottomRight; break;
                        default: alignment = Alignment.center;
                      }
                      return Positioned.fill(
                        child: Align(
                          alignment: alignment,
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Text(
                              noteNumber.toString(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                color: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _playCongratulationsSound() async {
    final soundManager = Provider.of<SoundManager>(context, listen: false);
    if (!soundManager.soundEnabled) return;
    
    try {
      await _audioPlayer.play(AssetSource('sounds/congrats.mp3'));
    } catch (e) {
      // Ses dosyası yoksa veya hata varsa sessizce devam et
      debugPrint('Error playing congratulations sound: $e');
    }
  }

  void _playWrongAnswerSound() async {
    final soundManager = Provider.of<SoundManager>(context, listen: false);
    if (!soundManager.soundEnabled) return;
    
    try {
      await _audioPlayer.play(AssetSource('sounds/wronganswer.mp3'));
    } catch (e) {
      // Ses dosyası yoksa veya hata varsa sessizce devam et
      debugPrint('Error playing wrong answer sound: $e');
    }
  }

  void _playColumnCompletionSound() async {
    final soundManager = Provider.of<SoundManager>(context, listen: false);
    if (!soundManager.soundEnabled) return;
    
    try {
      await _audioPlayer.play(AssetSource('sounds/columncompletion.mp3'));
    } catch (e) {
      // Ses dosyası yoksa veya hata varsa sessizce devam et
      debugPrint('Error playing column completion sound: $e');
    }
  }

  // Skorları kaydet
  Future<void> _saveScore() async {
    final profileManager = Provider.of<ProfileManager>(context, listen: false);
    
    // Guest modunda ise skor kaydetme
    if (profileManager.isGuestMode || profileManager.currentProfile == null) {
      return;
    }

    // Günlük oyun kontrolü
    final now = DateTime.now();
    final gameDate = game.startTime != null
        ? DateTime(game.startTime!.year, game.startTime!.month, game.startTime!.day)
        : null;
    final today = DateTime(now.year, now.month, now.day);
    final isDailyGame = gameDate != null && gameDate == today;

    final score = GameScore(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      profileId: profileManager.currentProfile!.id,
      difficulty: game.difficulty,
      score: game.score,
      elapsedSeconds: game.elapsedSeconds,
      completedAt: now,
      isDailyGame: isDailyGame,
    );

    await profileManager.saveScore(score);
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Congratulations!'),
          content: Text('You have successfully completed the Sudoku!\n\nScore: ${game.score}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Dialog'u kapat
                // Tamamlanmış oyunu temizle
                widget.gameStateManager.clearGame();
                Navigator.pop(context); // Oyun sayfasından çık
              },
              child: const Text('Back to Home'),
            ),
          ],
        );
      },
    );
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Game Over'),
          content: const Text('You made 3 errors. Game lost!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Dialog'u kapat
                // Oyunu temizle
                widget.gameStateManager.clearGame();
                Navigator.pop(context); // Oyun sayfasından çık
              },
              child: const Text('Back to Home'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HighlightColorManager>(
      builder: (context, highlightColorManager, child) {
        return Scaffold(
          appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Sudoku'),
            const SizedBox(width: 8),
            Consumer<ProfileManager>(
              builder: (context, profileManager, child) {
                if (profileManager.isGuestMode || profileManager.currentProfile == null) {
                  return const SizedBox.shrink();
                }
                
                final profile = profileManager.currentProfile!;
                return Consumer<ProfileVisibilityManager>(
                  builder: (context, visibilityManager, child) {
                    String displayText;
                    
                    // Eğer tüm bilgiler gizliyse "no name user" göster
                    if (visibilityManager.isAllInfoHidden) {
                      displayText = 'no name user';
                    } else if (profile.displayName != null && profile.displayName!.isNotEmpty) {
                      // Display name varsa onu göster
                      displayText = profile.displayName!;
                    } else if (visibilityManager.showName) {
                      // İsim gösteriliyorsa fullName göster
                      displayText = profile.fullName;
                    } else {
                      // Hiçbiri gösterilmiyorsa "no name user"
                      displayText = 'no name user';
                    }
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        displayText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          // Zaman Sayacı
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer,
                    size: 20,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDuration(_elapsedTime),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              _stopTimerAndSave();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isLandscape = orientation == Orientation.landscape;

          if (!isLandscape) {
            // Portrait: Orijinal düzen (üstte skor, ortada grid, altta butonlar)
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildScoreContainer(),
                      if (hasErrorLimit) _buildErrorContainer(),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = constraints.maxWidth < constraints.maxHeight
                          ? constraints.maxWidth
                          : constraints.maxHeight;
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SizedBox(
                            width: size,
                            height: size,
                            child: _buildSudokuGrid(highlightColorManager),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _buildPortraitNumberButtons(),
              ],
            );
          }

          // Landscape: Sol skor/hata, orta grid, sağ sayı butonları (2 sütun)
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sol: Skor ve Hata - kameradan kaçınmak için sola extra padding (56px)
              Padding(
                padding: const EdgeInsets.only(left: 56.0, right: 8.0, top: 12.0, bottom: 12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildScoreContainer(),
                    if (hasErrorLimit) ...[
                      const SizedBox(height: 12),
                      _buildErrorContainer(),
                    ],
                  ],
                ),
              ),

              /// Orta: Sudoku Grid - Landscape'ta biraz küçültülmüş (tam görünsün diye)
              Expanded(
                flex: 2,
                child: LayoutBuilder(
                  builder: (context, innerConstraints) {
                    final availableWidth = innerConstraints.maxWidth;
                    final availableHeight = innerConstraints.maxHeight;
                    final maxSize = availableWidth < availableHeight
                        ? availableWidth
                        : availableHeight;
                    final gridSize = maxSize * 0.88; // %88 - tablonun tam görünmesi için
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: gridSize,
                          height: gridSize,
                          child: _buildSudokuGrid(highlightColorManager),
                        ),
            ),
          );
        },
      ),
    ),

              /// Sağ: Sayı Butonları - 2 sütun (1-5 | 6-9 + sil)
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ElevatedButton(
                          onPressed: () => setState(() => _isNoteMode = !_isNoteMode),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade300,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(12),
                            minimumSize: const Size(44, 44),
                            shape: const CircleBorder(),
                          ),
                          child: Icon(
                            _isNoteMode ? Icons.edit : Icons.edit_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      // 2 sütun: sol 1-5, sağ 6-9 + sil
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(5, (i) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: _buildLandscapeNumberButton(i + 1),
                            )),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ...List.generate(4, (i) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: _buildLandscapeNumberButton(i + 6),
                              )),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: clearCell,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade300,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.all(12),
                                  minimumSize: const Size(44, 44),
                                  shape: const CircleBorder(),
                                ),
                                child: const Icon(Icons.delete, size: 22),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  },
);
  }
}
