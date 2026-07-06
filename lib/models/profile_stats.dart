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

  const ProfileStats({
    required this.overall,
    required this.easy,
    required this.medium,
    required this.hard,
  });

  bool get hasAnyGames => overall.hasGames;

  factory ProfileStats.fromScores(List<GameScore> scores) {
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
}
