import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../models/game_score.dart';
import '../models/user_profile.dart';

class SupabaseProfileRepository {
  SupabaseClient get _client => Supabase.instance.client;

  bool get isAvailable => AppConfig.isSupabaseConfigured;

  // ---------------------------------------------------------------------------
  // Mappers
  // ---------------------------------------------------------------------------

  Map<String, dynamic> profileToRow(UserProfile profile) {
    return {
      'id': profile.id,
      'email': profile.email.toLowerCase(),
      'first_name': profile.firstName,
      'last_name': profile.lastName,
      'birth_date': profile.birthDate.toIso8601String(),
      'avatar_path': profile.avatarPath,
      'cover_image_path': profile.coverImagePath,
      'display_name': profile.displayName,
      'avatar_color': profile.avatarColor,
      'cover_image_color': profile.coverImageColor,
      'created_at': profile.createdAt.toIso8601String(),
      'last_played_at': profile.lastPlayedAt?.toIso8601String(),
      'email_verified': profile.emailVerified,
      'password_hash': profile.passwordHash,
    };
  }

  UserProfile profileFromRow(Map<String, dynamic> row) {
    return UserProfile(
      id: row['id'] as String,
      email: row['email'] as String,
      firstName: row['first_name'] as String,
      lastName: row['last_name'] as String,
      birthDate: DateTime.parse(row['birth_date'] as String),
      avatarPath: row['avatar_path'] as String?,
      coverImagePath: row['cover_image_path'] as String?,
      displayName: row['display_name'] as String?,
      avatarColor: row['avatar_color'] as int?,
      coverImageColor: row['cover_image_color'] as int?,
      createdAt: DateTime.parse(row['created_at'] as String),
      lastPlayedAt: row['last_played_at'] != null
          ? DateTime.parse(row['last_played_at'] as String)
          : null,
      emailVerified: row['email_verified'] as bool? ?? false,
      passwordHash: row['password_hash'] as String? ?? '',
    );
  }

  Map<String, dynamic> scoreToRow(GameScore score) {
    return {
      'id': score.id,
      'profile_id': score.profileId,
      'difficulty': score.difficulty,
      'score': score.score,
      'elapsed_seconds': score.elapsedSeconds,
      'completed_at': score.completedAt.toIso8601String(),
      'is_daily_game': score.isDailyGame,
    };
  }

  GameScore scoreFromRow(Map<String, dynamic> row) {
    return GameScore(
      id: row['id'] as String,
      profileId: row['profile_id'] as String,
      difficulty: row['difficulty'] as String,
      score: row['score'] as int,
      elapsedSeconds: row['elapsed_seconds'] as int,
      completedAt: DateTime.parse(row['completed_at'] as String),
      isDailyGame: row['is_daily_game'] as bool? ?? false,
    );
  }

  Map<String, dynamic> sqliteProfileToRow(Map<String, dynamic> map) {
    return {
      'id': map['id'],
      'email': (map['email'] as String).toLowerCase(),
      'first_name': map['firstName'] ?? map['name'] ?? 'User',
      'last_name': map['lastName'] ?? '',
      'birth_date': map['birthDate'] ?? DateTime.now().toIso8601String(),
      'avatar_path': map['avatarPath'],
      'cover_image_path': map['coverImagePath'],
      'display_name': map['displayName'],
      'avatar_color': map['avatarColor'],
      'cover_image_color': map['coverImageColor'],
      'created_at': map['createdAt'] ?? DateTime.now().toIso8601String(),
      'last_played_at': map['lastPlayedAt'],
      'email_verified': (map['emailVerified'] as int? ?? 0) == 1,
      'password_hash': map['passwordHash'] ?? '',
    };
  }

  Map<String, dynamic> sqliteScoreToRow(Map<String, dynamic> map) {
    return {
      'id': map['id'],
      'profile_id': map['profileId'],
      'difficulty': map['difficulty'],
      'score': map['score'],
      'elapsed_seconds': map['elapsedSeconds'],
      'completed_at': map['completedAt'],
      'is_daily_game': (map['isDailyGame'] as int? ?? 0) == 1,
    };
  }

  // ---------------------------------------------------------------------------
  // Migration
  // ---------------------------------------------------------------------------

  Future<void> upsertProfilesFromSqlite(
    List<Map<String, dynamic>> sqliteRows,
  ) async {
    if (sqliteRows.isEmpty) return;

    await _client.from('profiles').upsert(
          sqliteRows.map(sqliteProfileToRow).toList(),
          onConflict: 'id',
        );
  }

  Future<void> upsertScoresFromSqlite(
    List<Map<String, dynamic>> sqliteRows,
  ) async {
    if (sqliteRows.isEmpty) return;

    await _client.from('game_scores').upsert(
          sqliteRows.map(sqliteScoreToRow).toList(),
          onConflict: 'id',
        );
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  Future<UserProfile?> getProfileByEmail(String email) async {
    final rows = await _client
        .from('profiles')
        .select()
        .eq('email', email.toLowerCase())
        .maybeSingle();

    if (rows == null) return null;
    return profileFromRow(rows);
  }

  Future<UserProfile?> getProfile(String profileId) async {
    final rows = await _client
        .from('profiles')
        .select()
        .eq('id', profileId)
        .maybeSingle();

    if (rows == null) return null;
    return profileFromRow(rows);
  }

  Future<void> insertProfile(UserProfile profile) async {
    try {
      await _client.from('profiles').insert(profileToRow(profile));
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('Profile already exists for this email');
      }
      rethrow;
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    await _client
        .from('profiles')
        .update(profileToRow(profile))
        .eq('id', profile.id);
  }

  Future<void> deleteProfile(String profileId) async {
    await _client.from('profiles').delete().eq('id', profileId);
  }

  Future<void> updateLastPlayed(String profileId, DateTime playedAt) async {
    await _client.from('profiles').update({
      'last_played_at': playedAt.toIso8601String(),
    }).eq('id', profileId);
  }

  Future<void> saveScore(GameScore score) async {
    await _client.from('game_scores').upsert(
          scoreToRow(score),
          onConflict: 'id',
        );
  }

  Future<List<GameScore>> getProfileScores(
    String profileId, {
    String? difficulty,
  }) async {
    var query = _client
        .from('game_scores')
        .select()
        .eq('profile_id', profileId);

    if (difficulty != null) {
      query = query.eq('difficulty', difficulty);
    }

    final rows = await query.order('completed_at', ascending: false);
    return (rows as List)
        .map((row) => scoreFromRow(row as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getStats() async {
    final profiles =
        await _client.from('profiles').select('id') as List;
    final scores =
        await _client.from('game_scores').select('id') as List;

    return {
      'profilesCount': profiles.length,
      'scoresCount': scores.length,
      'databasePath': AppConfig.supabaseUrl,
      'storageType': 'supabase',
      'migrationComplete': true,
      'usingSupabase': true,
    };
  }
}
