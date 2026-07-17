import 'game_score.dart';

class DifficultyStats {
  final String difficulty;
  final int totalGames;
  final int totalScore;
  final int bestScore;
  final int averageScore;
  final int totalTime;

  const DifficultyStats({
    required this.difficulty,
    required this.totalGames,
    required this.totalScore,
    required this.bestScore,
    required this.averageScore,
    required this.totalTime,
  });

  bool get hasGames => totalGames > 0;

  factory DifficultyStats.empty(String difficulty) {
    return DifficultyStats(
      difficulty: difficulty,
      totalGames: 0,
      totalScore: 0,
      bestScore: 0,
      averageScore: 0,
      totalTime: 0,
    );
  }

  factory DifficultyStats.fromScores(
    String difficulty,
    List<GameScore> scores,
  ) {
    if (scores.isEmpty) return DifficultyStats.empty(difficulty);

    final totalGames = scores.length;
    final totalScore = scores.fold<int>(0, (sum, s) => sum + s.score);
    final bestScore = scores.map((s) => s.score).reduce((a, b) => a > b ? a : b);
    final averageScore = (totalScore / totalGames).round();
    final totalTime =
        scores.fold<int>(0, (sum, s) => sum + s.elapsedSeconds);

    return DifficultyStats(
      difficulty: difficulty,
      totalGames: totalGames,
      totalScore: totalScore,
      bestScore: bestScore,
      averageScore: averageScore,
      totalTime: totalTime,
    );
  }
}

class ProfileStats {
  final DifficultyStats overall;
  final DifficultyStats easy;
  final DifficultyStats medium;
  final DifficultyStats hard;
  /// Consecutive calendar days with at least one completed game.
  /// Active if the last play was today or yesterday; otherwise 0.
  final int currentStreak;
  /// Longest consecutive-day run across all completed games.
  final int bestStreak;

  const ProfileStats({
    required this.overall,
    required this.easy,
    required this.medium,
    required this.hard,
    this.currentStreak = 0,
    this.bestStreak = 0,
  });

  bool get hasAnyGames => overall.hasGames;

  factory ProfileStats.fromScores(List<GameScore> scores) {
    final streaks = _computeStreaks(scores);
    return ProfileStats(
      overall: DifficultyStats.fromScores('All', scores),
      easy: DifficultyStats.fromScores(
        'Easy',
        scores.where((s) => s.difficulty == 'Easy').toList(),
      ),
      medium: DifficultyStats.fromScores(
        'Medium',
        scores.where((s) => s.difficulty == 'Medium').toList(),
      ),
      hard: DifficultyStats.fromScores(
        'Hard',
        scores.where((s) => s.difficulty == 'Hard').toList(),
      ),
      currentStreak: streaks.current,
      bestStreak: streaks.best,
    );
  }

  static ProfileStats empty() {
    return ProfileStats(
      overall: DifficultyStats.empty('All'),
      easy: DifficultyStats.empty('Easy'),
      medium: DifficultyStats.empty('Medium'),
      hard: DifficultyStats.empty('Hard'),
    );
  }

  DifficultyStats forDifficulty(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return easy;
      case 'Medium':
        return medium;
      case 'Hard':
        return hard;
      default:
        return overall;
    }
  }

  static DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  static ({int current, int best}) _computeStreaks(List<GameScore> scores) {
    if (scores.isEmpty) return (current: 0, best: 0);

    final days = scores.map((s) => _dateOnly(s.completedAt)).toSet().toList()
      ..sort((a, b) => b.compareTo(a));

    var best = 1;
    var run = 1;
    for (var i = 1; i < days.length; i++) {
      if (days[i - 1].difference(days[i]).inDays == 1) {
        run++;
        if (run > best) best = run;
      } else {
        run = 1;
      }
    }

    final today = _dateOnly(DateTime.now());
    final gapFromToday = today.difference(days.first).inDays;
    var current = 0;
    if (gapFromToday <= 1) {
      current = 1;
      for (var i = 1; i < days.length; i++) {
        if (days[i - 1].difference(days[i]).inDays == 1) {
          current++;
        } else {
          break;
        }
      }
    }

    return (current: current, best: best);
  }
}
