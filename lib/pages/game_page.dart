import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import '../services/game_state_manager.dart';
import '../services/sound_manager.dart';
import '../models/sudoku_game.dart';
import '../services/sudoku_generator.dart';

class GamePage extends StatefulWidget {
  final GameStateManager gameStateManager;

  const GamePage({super.key, required this.gameStateManager});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late SudokuGame game;
  int selectedRow = -1;
  int selectedCol = -1;
  Timer? _timer;
  DateTime? _timerStartTime; // Timer'ın bu oturumda başladığı zaman
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool get hasErrorLimit => game.difficulty == 'Medium' || game.difficulty == 'Hard';

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
    super.dispose();
  }

  void _startTimer() {
    // Timer başlatıldığında şimdiki zamanı kaydet
    _timerStartTime = DateTime.now();
    
    // İlk güncelleme
    if (mounted) {
      setState(() {});
    }
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !game.isCompleted) {
        setState(() {});
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

  void setNumber(int number) {
    if (selectedRow == -1 || selectedCol == -1) return;
    if (game.isGiven[selectedRow][selectedCol]) return; // Verilen sayılar değiştirilemez
    if (game.isCompleted) return; // Oyun tamamlandıysa hamle yapılamaz

    // Çözümle karşılaştır
    bool isCorrect = number == game.solution[selectedRow][selectedCol];
    int previousValue = game.currentBoard[selectedRow][selectedCol];
    
    setState(() {
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
      
      // Oyun tamamlandı mı kontrol et
      if (SudokuGenerator.isGameComplete(game.currentBoard, game.solution)) {
        game.isCompleted = true;
        _stopTimerAndSave();
        widget.gameStateManager.completeGame();
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
      widget.gameStateManager.updateGame(game);
    });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sudoku'),
        centerTitle: true,
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
      body: Column(
        children: [
          // Skor ve Hata Sayacı
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Skor
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1), // Koyu yeşil açık ton
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Score',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF2E7D32), // Koyu yeşil
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        game.score.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B5E20), // Daha koyu yeşil
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Error Counter (only for Medium and Hard levels)
                if (hasErrorLimit)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.shade200,
                      ),
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (index) {
                            return Icon(
                              index < game.errorCount 
                                  ? Icons.close 
                                  : Icons.close_outlined,
                              color: index < game.errorCount 
                                  ? Colors.red 
                                  : Colors.grey.shade300,
                              size: 24,
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          /// Sudoku Grid
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 9,
                  ),
                  itemCount: 81,
                  itemBuilder: (context, index) {
                    int row = index ~/ 9;
                    int col = index % 9;

                    bool isSelected = row == selectedRow && col == selectedCol;
                    bool isGiven = game.isGiven[row][col];
                    int value = game.currentBoard[row][col];
                    bool isSameValue = _isSameValueCell(row, col);
                    
                    // Geçerlilik kontrolü
                    bool isValid = value == 0 || 
                        SudokuGenerator.isValidMove(game.currentBoard, row, col, value);
                    
                    // Çözümle karşılaştır (hata sayacı için)
                    bool isCorrect = value == 0 || value == game.solution[row][col];
                    
                    // Error check (only for user-entered numbers)
                    // For Medium and Hard: compare with solution, for Easy: check validity
                    bool hasError = !isGiven && value != 0 && (
                      hasErrorLimit 
                        ? !isCorrect  // Medium/Hard: compare with solution
                        : !isValid     // Easy: check validity
                    );

                    // Dark mode kontrolü
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    
                    // Renk belirleme
                    Color textColor;
                    if (isGiven) {
                      // Baştan verilen sayılar: aynı sayıya tıklandıysa kırmızı, değilse siyah/beyaz
                      textColor = isSameValue 
                          ? Colors.red 
                          : (isDark ? Colors.white : Colors.black);
                    } else {
                      // Sonradan eklenen sayılar: aynı sayıya tıklandıysa kırmızı, değilse mavi (geçerli)
                      if (isSameValue) {
                        textColor = Colors.red;
                      } else {
                        textColor = isValid
                            ? (isDark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32)) // Koyu yeşil
                            : (isDark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32)); // Hata durumunda sayı rengi değişmez, sadece arka plan kırmızı olur
                      }
                    }
                    
                    // Arka plan rengi belirleme
                    Color backgroundColor;
                    if (isSelected) {
                      // Seçili hücre: eğer hatalıysa pembemsi, değilse koyu yeşil
                      backgroundColor = hasError 
                          ? Colors.pink.withOpacity(0.4)
                          : (isDark ? const Color(0xFF2E7D32).withOpacity(0.3) : const Color(0xFF2E7D32).withOpacity(0.2));
                    } else if (hasError) {
                      // Hatalı sayı: saydam pembe arka plan
                      backgroundColor = Colors.pink.withOpacity(0.3);
                    } else if (isGiven) {
                      backgroundColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
                    } else {
                      backgroundColor = isDark ? Colors.grey.shade900 : Colors.white;
                    }

                    return GestureDetector(
                      onTap: () => selectCell(row, col),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              width: row % 3 == 0 ? 2.5 : 0.5,
                              color: Colors.grey.shade600,
                            ),
                            left: BorderSide(
                              width: col % 3 == 0 ? 2.5 : 0.5,
                              color: Colors.grey.shade600,
                            ),
                            right: BorderSide(
                              width: col == 8 ? 2.5 : 0.5,
                              color: Colors.grey.shade600,
                            ),
                            bottom: BorderSide(
                              width: row == 8 ? 2.5 : 0.5,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          color: backgroundColor,
                        ),
                        child: Center(
                          child: Text(
                            value == 0 ? '' : value.toString(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900, // Tüm sayılar kalın
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          /// Number Buttons - İki Satır
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              children: [
                // Üst satır: 1-5
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (index) {
                    int number = index + 1;
                    bool isDisabled = _isNumberComplete(number);
                    return ElevatedButton(
                      onPressed: isDisabled ? null : () => setNumber(number),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: isDisabled ? Colors.grey : const Color(0xFF2E7D32), // Koyu yeşil
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        minimumSize: const Size(50, 50),
                      ),
                      child: Text(
                        number.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDisabled ? Colors.grey.shade400 : Colors.white,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                // Alt satır: 6-9 ve Sil butonu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 6-9 sayılar
                    ...List.generate(4, (index) {
                      int number = index + 6;
                      bool isDisabled = _isNumberComplete(number);
                      return ElevatedButton(
                        onPressed: isDisabled ? null : () => setNumber(number),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDisabled ? Colors.grey : const Color(0xFF2E7D32), // Koyu yeşil
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                          minimumSize: const Size(50, 50),
                        ),
                        child: Text(
                          number.toString(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDisabled ? Colors.grey.shade400 : Colors.white,
                          ),
                        ),
                      );
                    }),
                    // Sil butonu
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
      ),
    );
  }
}
