class SudokuGame {
  final List<List<int>> puzzle; // Başlangıç bulmacası (0 = boş)
  final List<List<int>> solution; // Çözüm
  List<List<int>> currentBoard; // Mevcut durum
  final List<List<bool>> isGiven; // Verilen sayılar (değiştirilemez)
  bool isCompleted;
  final String difficulty; // Difficulty level
  int score; // Skor
  int errorCount; // Hata sayısı
  DateTime? startTime; // Oyun başlangıç zamanı (timer için)
  DateTime? dailyPuzzleDate; // Günlük bulmacanın takvim tarihi
  int elapsedSeconds; // Toplam geçen saniye (oyun çıkıldığında kaydedilir) - mutable
  List<List<Set<int>>> notes; // Notlar (her hücre için olası sayılar)

  SudokuGame({
    required this.puzzle,
    required this.solution,
    List<List<int>>? currentBoard,
    required this.isGiven,
    this.isCompleted = false,
    required this.difficulty,
    this.score = 0,
    this.errorCount = 0,
    DateTime? startTime,
    this.dailyPuzzleDate,
    this.elapsedSeconds = 0,
    List<List<Set<int>>>? notes,
  }) : currentBoard = currentBoard ?? puzzle.map((row) => List<int>.from(row)).toList(),
        startTime = startTime ?? DateTime.now(),
        notes = notes ?? List.generate(9, (_) => List.generate(9, (_) => <int>{}));

  // Oyunu JSON'a çevir (kayıt için)
  Map<String, dynamic> toJson() {
    return {
      'puzzle': puzzle,
      'solution': solution,
      'currentBoard': currentBoard,
      'isGiven': isGiven,
      'isCompleted': isCompleted,
      'difficulty': difficulty,
      'score': score,
      'errorCount': errorCount,
      'startTime': startTime?.toIso8601String(),
      'dailyPuzzleDate': dailyPuzzleDate?.toIso8601String(),
      'elapsedSeconds': elapsedSeconds,
      'notes': notes.map((row) => row.map((noteSet) => noteSet.toList()).toList()).toList(),
    };
  }

  // JSON'dan oyun oluştur
  factory SudokuGame.fromJson(Map<String, dynamic> json) {
    List<List<Set<int>>> notesData;
    if (json['notes'] != null) {
      notesData = List<List<Set<int>>>.from(
        json['notes'].map((row) => List<Set<int>>.from(
          row.map((noteList) => Set<int>.from(noteList))
        ))
      );
    } else {
      notesData = List.generate(9, (_) => List.generate(9, (_) => <int>{}));
    }
    
    return SudokuGame(
      puzzle: List<List<int>>.from(json['puzzle'].map((row) => List<int>.from(row))),
      solution: List<List<int>>.from(json['solution'].map((row) => List<int>.from(row))),
      currentBoard: List<List<int>>.from(json['currentBoard'].map((row) => List<int>.from(row))),
      isGiven: List<List<bool>>.from(json['isGiven'].map((row) => List<bool>.from(row))),
      isCompleted: json['isCompleted'] ?? false,
      difficulty: json['difficulty'] ?? 'Medium',
      score: json['score'] ?? 0,
      errorCount: json['errorCount'] ?? 0,
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      dailyPuzzleDate: json['dailyPuzzleDate'] != null
          ? DateTime.parse(json['dailyPuzzleDate'])
          : null,
      elapsedSeconds: json['elapsedSeconds'] ?? 0,
      notes: notesData,
    );
  }

  // Yeni oyun oluştur
  SudokuGame copyWithNewBoard(List<List<int>> newPuzzle, List<List<int>> newSolution, List<List<bool>> newIsGiven) {
    return SudokuGame(
      puzzle: newPuzzle,
      solution: newSolution,
      currentBoard: newPuzzle.map((row) => List<int>.from(row)).toList(),
      isGiven: newIsGiven,
      isCompleted: false,
      difficulty: difficulty,
      score: 0,
      errorCount: 0,
      startTime: DateTime.now(),
      elapsedSeconds: 0,
      notes: List.generate(9, (_) => List.generate(9, (_) => <int>{})),
    );
  }
}

