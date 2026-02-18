class GameScore {
  final String id;
  final String profileId; // Hangi profile ait
  final String difficulty;
  final int score;
  final int elapsedSeconds;
  final DateTime completedAt;
  final bool isDailyGame;

  GameScore({
    required this.id,
    required this.profileId,
    required this.difficulty,
    required this.score,
    required this.elapsedSeconds,
    required this.completedAt,
    this.isDailyGame = false,
  });

  // JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profileId': profileId,
      'difficulty': difficulty,
      'score': score,
      'elapsedSeconds': elapsedSeconds,
      'completedAt': completedAt.toIso8601String(),
      'isDailyGame': isDailyGame,
    };
  }

  // JSON'dan oluştur
  factory GameScore.fromJson(Map<String, dynamic> json) {
    return GameScore(
      id: json['id'] as String,
      profileId: json['profileId'] as String,
      difficulty: json['difficulty'] as String,
      score: json['score'] as int,
      elapsedSeconds: json['elapsedSeconds'] as int,
      completedAt: DateTime.parse(json['completedAt'] as String),
      isDailyGame: json['isDailyGame'] as bool? ?? false,
    );
  }
}
