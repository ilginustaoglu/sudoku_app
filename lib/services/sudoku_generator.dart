import 'dart:math';
import '../models/sudoku_game.dart';

class SudokuGenerator {
  static final Random _random = Random();

  // Difficulty levels: number of cells to remove
  static const Map<String, int> difficultyLevels = {
    'Easy': 35,
    'Medium': 45,
    'Hard': 55,
  };

  // Yeni bir Sudoku oyunu oluştur
  static SudokuGame generateNewGame({String difficulty = 'Medium'}) {
    // Önce tam dolu bir geçerli Sudoku oluştur (çözüm)
    List<List<int>> solution = _generateCompleteSudoku();
    
    // Kopyasını al ve bazı sayıları sil (bulmaca oluştur)
    List<List<int>> puzzle = solution.map((row) => List<int>.from(row)).toList();
    List<List<bool>> isGiven = List.generate(9, (_) => List.generate(9, (_) => false));
    
    int cellsToRemove = difficultyLevels[difficulty] ?? 45;
    _removeCells(puzzle, cellsToRemove, isGiven);

    return SudokuGame(
      puzzle: puzzle,
      solution: solution,
      isGiven: isGiven,
      isCompleted: false,
      difficulty: difficulty,
      score: 0,
      errorCount: 0,
      startTime: DateTime.now(),
      elapsedSeconds: 0,
    );
  }

  // Tam dolu geçerli bir Sudoku oluştur
  static List<List<int>> _generateCompleteSudoku() {
    List<List<int>> board = List.generate(9, (_) => List.generate(9, (_) => 0));
    
    // İlk satırı rastgele doldur
    List<int> firstRow = List.generate(9, (i) => i + 1);
    firstRow.shuffle(_random);
    board[0] = firstRow;

    // Geri kalanı doldur
    _solveSudoku(board);
    
    return board;
  }

  // Sudoku çözme algoritması (backtracking)
  static bool _solveSudoku(List<List<int>> board) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (board[row][col] == 0) {
          List<int> numbers = List.generate(9, (i) => i + 1);
          numbers.shuffle(_random);
          
          for (int num in numbers) {
            if (_isValid(board, row, col, num)) {
              board[row][col] = num;
              
              if (_solveSudoku(board)) {
                return true;
              }
              
              board[row][col] = 0; // Geri al
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  // Bir sayının geçerli olup olmadığını kontrol et
  static bool _isValid(List<List<int>> board, int row, int col, int num) {
    // Satır kontrolü
    for (int x = 0; x < 9; x++) {
      if (board[row][x] == num) return false;
    }

    // Sütun kontrolü
    for (int x = 0; x < 9; x++) {
      if (board[x][col] == num) return false;
    }

    // 3x3 kutu kontrolü
    int startRow = row - row % 3;
    int startCol = col - col % 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (board[i + startRow][j + startCol] == num) return false;
      }
    }

    return true;
  }

  // Belirli sayıda hücreyi rastgele sil
  static void _removeCells(List<List<int>> board, int count, List<List<bool>> isGiven) {
    // Önce tüm hücreleri verilen olarak işaretle
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        isGiven[i][j] = true;
      }
    }

    // Rastgele hücreleri sil
    int removed = 0;
    int attempts = 0;
    const maxAttempts = 200;
    Set<String> removedCells = {};

    while (removed < count && attempts < maxAttempts) {
      int row = _random.nextInt(9);
      int col = _random.nextInt(9);
      String key = '$row,$col';

      if (!removedCells.contains(key) && board[row][col] != 0) {
        board[row][col] = 0;
        isGiven[row][col] = false; // Silinen hücreler verilen değil
        removedCells.add(key);
        removed++;
      }
      attempts++;
    }
  }

  // Oyunun tamamlanıp tamamlanmadığını kontrol et
  static bool isGameComplete(List<List<int>> currentBoard, List<List<int>> solution) {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (currentBoard[i][j] != solution[i][j]) {
          return false;
        }
      }
    }
    return true;
  }

  // Bir hamlenin geçerli olup olmadığını kontrol et
  static bool isValidMove(List<List<int>> board, int row, int col, int num) {
    if (num == 0) return true; // Silme her zaman geçerli

    // Satır kontrolü
    for (int x = 0; x < 9; x++) {
      if (x != col && board[row][x] == num) return false;
    }

    // Sütun kontrolü
    for (int x = 0; x < 9; x++) {
      if (x != row && board[x][col] == num) return false;
    }

    // 3x3 kutu kontrolü
    int startRow = row - row % 3;
    int startCol = col - col % 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        int checkRow = i + startRow;
        int checkCol = j + startCol;
        if (checkRow != row && checkCol != col && board[checkRow][checkCol] == num) {
          return false;
        }
      }
    }

    return true;
  }
}

