import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../models/friendship.dart';
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
      'friend_code': profile.friendCode,
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
      friendCode: row['friend_code'] as String? ?? '',
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

  Map<String, dynamic> friendshipToRow(Friendship friendship) {
    return {
      'id': friendship.id,
      'requester_id': friendship.requesterId,
      'addressee_id': friendship.addresseeId,
      'status': friendship.status.name,
      'created_at': friendship.createdAt.toIso8601String(),
      'responded_at': friendship.respondedAt?.toIso8601String(),
      'requester_seen_at': friendship.requesterSeenAt?.toIso8601String(),
      'addressee_seen_at': friendship.addresseeSeenAt?.toIso8601String(),
    };
  }

  Friendship friendshipFromRow(Map<String, dynamic> row) {
    return Friendship(
      id: row['id'] as String,
      requesterId: row['requester_id'] as String,
      addresseeId: row['addressee_id'] as String,
      status: FriendshipStatus.fromValue(row['status'] as String?),
      createdAt: DateTime.parse(row['created_at'] as String),
      respondedAt: row['responded_at'] != null
          ? DateTime.parse(row['responded_at'] as String)
          : null,
      requesterSeenAt: row['requester_seen_at'] != null
          ? DateTime.parse(row['requester_seen_at'] as String)
          : null,
      addresseeSeenAt: row['addressee_seen_at'] != null
          ? DateTime.parse(row['addressee_seen_at'] as String)
          : null,
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
      'friend_code': map['friendCode'] ?? '',
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

    await _client
        .from('profiles')
        .upsert(sqliteRows.map(sqliteProfileToRow).toList(), onConflict: 'id');
  }

  Future<void> upsertScoresFromSqlite(
    List<Map<String, dynamic>> sqliteRows,
  ) async {
    if (sqliteRows.isEmpty) return;

    await _client
        .from('game_scores')
        .upsert(sqliteRows.map(sqliteScoreToRow).toList(), onConflict: 'id');
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

  Future<UserProfile?> getProfileByFriendCode(String friendCode) async {
    final rows = await _client
        .from('profiles')
        .select()
        .eq('friend_code', friendCode)
        .maybeSingle();

    if (rows == null) return null;
    return profileFromRow(rows);
  }

  Future<bool> isFriendCodeTaken(String friendCode) async {
    final rows = await _client
        .from('profiles')
        .select('id')
        .eq('friend_code', friendCode)
        .maybeSingle();
    return rows != null;
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

  Future<void> updateFriendCode(String profileId, String friendCode) async {
    await _client
        .from('profiles')
        .update({'friend_code': friendCode})
        .eq('id', profileId);
  }

  Future<void> deleteProfile(String profileId) async {
    await _client.from('profiles').delete().eq('id', profileId);
  }

  Future<void> updateLastPlayed(String profileId, DateTime playedAt) async {
    await _client
        .from('profiles')
        .update({'last_played_at': playedAt.toIso8601String()})
        .eq('id', profileId);
  }

  Future<void> saveScore(GameScore score) async {
    await _client
        .from('game_scores')
        .upsert(scoreToRow(score), onConflict: 'id');
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

  Future<void> insertFriendship(Friendship friendship) async {
    try {
      await _client.from('friendships').insert(friendshipToRow(friendship));
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('Friend request already exists');
      }
      if (_isMissingFriendsSchema(e)) {
        throw Exception('Friends feature is not set up on the server yet');
      }
      rethrow;
    }
  }

  Future<List<Friendship>> getFriendships(String profileId) async {
    try {
      final rows = await _client
          .from('friendships')
          .select()
          .or('requester_id.eq.$profileId,addressee_id.eq.$profileId')
          .eq('status', FriendshipStatus.accepted.name)
          .order('created_at', ascending: false);

      return (rows as List)
          .map((row) => friendshipFromRow(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      if (_isMissingFriendsSchema(e)) {
        throw Exception('Friends feature is not set up on the server yet');
      }
      rethrow;
    }
  }

  Future<bool> areFriends(String profileIdA, String profileIdB) async {
    try {
      final rows = await _client
          .from('friendships')
          .select('id')
          .or(
            'and(requester_id.eq.$profileIdA,addressee_id.eq.$profileIdB),'
            'and(requester_id.eq.$profileIdB,addressee_id.eq.$profileIdA)',
          )
          .eq('status', FriendshipStatus.accepted.name)
          .maybeSingle();
      return rows != null;
    } on PostgrestException catch (e) {
      if (_isMissingFriendsSchema(e)) {
        throw Exception('Friends feature is not set up on the server yet');
      }
      rethrow;
    }
  }

  Future<Friendship?> getRelationship(
    String profileIdA,
    String profileIdB,
  ) async {
    final row = await _client
        .from('friendships')
        .select()
        .or(
          'and(requester_id.eq.$profileIdA,addressee_id.eq.$profileIdB),'
          'and(requester_id.eq.$profileIdB,addressee_id.eq.$profileIdA)',
        )
        .maybeSingle();
    return row == null ? null : friendshipFromRow(row);
  }

  Future<List<Friendship>> getFriendNotifications(String profileId) async {
    final rows = await _client
        .from('friendships')
        .select()
        .or(
          'and(addressee_id.eq.$profileId,status.eq.pending),'
          'and(requester_id.eq.$profileId,status.eq.accepted),'
          'and(addressee_id.eq.$profileId,status.eq.accepted)',
        )
        .order('created_at', ascending: false);
    return (rows as List)
        .map((row) => friendshipFromRow(row as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadFriendNotificationCount(String profileId) async {
    final rows = await _client
        .from('friendships')
        .select('id')
        .or(
          'and(addressee_id.eq.$profileId,status.eq.pending,addressee_seen_at.is.null),'
          'and(requester_id.eq.$profileId,status.eq.accepted,requester_seen_at.is.null)',
        );
    return (rows as List).length;
  }

  Future<void> markFriendNotificationsSeen(String profileId) async {
    final now = DateTime.now().toIso8601String();
    await _client
        .from('friendships')
        .update({'addressee_seen_at': now})
        .eq('addressee_id', profileId)
        .eq('status', FriendshipStatus.pending.name)
        .isFilter('addressee_seen_at', null);
    await _client
        .from('friendships')
        .update({'requester_seen_at': now})
        .eq('requester_id', profileId)
        .eq('status', FriendshipStatus.accepted.name)
        .isFilter('requester_seen_at', null);
  }

  Future<void> acceptFriendRequest(
    String friendshipId,
    String addresseeId,
  ) async {
    await _client
        .from('friendships')
        .update({
          'status': FriendshipStatus.accepted.name,
          'responded_at': DateTime.now().toIso8601String(),
          'requester_seen_at': null,
          'addressee_seen_at': DateTime.now().toIso8601String(),
        })
        .eq('id', friendshipId)
        .eq('addressee_id', addresseeId)
        .eq('status', FriendshipStatus.pending.name);
  }

  Future<void> rejectFriendRequest(
    String friendshipId,
    String addresseeId,
  ) async {
    await _client
        .from('friendships')
        .delete()
        .eq('id', friendshipId)
        .eq('addressee_id', addresseeId)
        .eq('status', FriendshipStatus.pending.name);
  }

  bool _isMissingFriendsSchema(PostgrestException e) {
    final message = e.message.toLowerCase();
    return e.code == 'PGRST205' ||
        e.code == '42703' ||
        message.contains('friendships') ||
        message.contains('friend_code');
  }

  Future<void> deleteFriendship(String friendshipId) async {
    await _client.from('friendships').delete().eq('id', friendshipId);
  }

  Future<void> deleteFriendshipBetween(
    String profileIdA,
    String profileIdB,
  ) async {
    await _client
        .from('friendships')
        .delete()
        .or(
          'and(requester_id.eq.$profileIdA,addressee_id.eq.$profileIdB),'
          'and(requester_id.eq.$profileIdB,addressee_id.eq.$profileIdA)',
        );
  }

  Future<Map<String, dynamic>> getStats() async {
    final profiles = await _client.from('profiles').select('id') as List;
    final scores = await _client.from('game_scores').select('id') as List;

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
