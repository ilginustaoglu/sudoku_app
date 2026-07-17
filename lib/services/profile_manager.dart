import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../config/app_config.dart';
import '../models/user_profile.dart';
import '../models/game_score.dart';
import '../models/friendship.dart';
import '../models/profile_stats.dart';
import 'onboarding_manager.dart';
import 'email_verification_service.dart';
import 'supabase_profile_repository.dart';

class ProfileManager extends ChangeNotifier {
  static const String _dbName = 'sudoku_profiles.db';
  static const int _dbVersion = 9; // friend requests + notifications
  static const String _migrationPrefKey = 'sqlite_migrated_to_supabase_v1';
  static final RegExp _friendCodePattern = RegExp(r'^\d{6}$');
  static final Random _random = Random.secure();

  final EmailVerificationService _emailService = EmailVerificationService();
  final SupabaseProfileRepository _supabaseRepo = SupabaseProfileRepository();
  bool _migrationComplete = false;

  bool get _useSupabase => AppConfig.isSupabaseConfigured && _migrationComplete;

  // Şifre hash'leme
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Şifre kontrolü
  bool _verifyPassword(String password, String hash) {
    return _hashPassword(password) == hash;
  }

  Database? _database;
  UserProfile? _currentProfile;
  bool _isGuestMode = true;
  bool _isInitialized = false;
  bool _isInitializing = false;
  Completer<void>? _initCompleter;

  UserProfile? get currentProfile => _currentProfile;
  bool get isGuestMode => _isGuestMode;
  bool get hasProfile => _currentProfile != null && !_isGuestMode;
  bool get isInitialized => _isInitialized;

  ProfileManager() {
    // Tamamen lazy initialization - sadece gerektiğinde başlat
    // UI render'ı hiç bloklamaz
    // Initialization'ı hemen başlat ama await etme (non-blocking)
    // Sadece bir kez başlatmak için kontrol et
    if (!_isInitialized && !_isInitializing) {
      Future.microtask(() {
        _initialize();
      });
    }
  }

  Future<void> _initialize() async {
    // Zaten initialize ediliyorsa veya edildiyse tekrar başlatma
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;
    _initCompleter = Completer<void>();

    try {
      final prefs = await SharedPreferences.getInstance();
      _migrationComplete = prefs.getBool(_migrationPrefKey) ?? false;

      final needsSqlite =
          !AppConfig.isSupabaseConfigured || !_migrationComplete;
      if (needsSqlite) {
        await _initDatabase();
      }

      if (AppConfig.isSupabaseConfigured && !_migrationComplete) {
        await _migrateSqliteToSupabaseIfNeeded();
      }

      await _loadCurrentProfile();
      if (_currentProfile != null && !_isGuestMode) {
        try {
          await ensureFriendCodeAssigned();
        } catch (e) {
          debugPrint('Friend code assignment deferred: $e');
        }
      }
      _isInitialized = true;
      debugPrint('ProfileManager initialized successfully');
      // Sadece bir kez notifyListeners çağır - gereksiz rebuild'leri önle
      notifyListeners();
      // Başarılı durumda completer'ı tamamla
      if (!_initCompleter!.isCompleted) {
        _initCompleter!.complete();
      }
    } catch (e) {
      debugPrint('Error initializing ProfileManager: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      // Hata olsa bile UI'ın açılmasına izin ver (login ekranı)
      _isInitialized = true;
      _currentProfile = null;
      _isGuestMode = true;
      notifyListeners();
      if (!_initCompleter!.isCompleted) {
        _initCompleter!.complete();
      }
    } finally {
      _isInitializing = false;
    }
  }

  // Database hazır olana kadar bekle
  Future<void> ensureInitialized() async {
    if (_isInitialized && (_useSupabase || _database != null)) return;

    // Eğer henüz başlatılmadıysa başlat
    if (!_isInitializing && !_isInitialized) {
      await _initialize();
      return;
    }

    // Completer varsa bekle
    if (_initCompleter != null) {
      await _initCompleter!.future;
    }

    // Eğer hala initialize olmadıysa tekrar dene
    if (!_isInitialized || (!_useSupabase && _database == null)) {
      throw Exception('Database initialization failed');
    }
  }

  /// SQLite'taki mevcut profil ve skorları Supabase'e taşır (tek seferlik).
  Future<void> _migrateSqliteToSupabaseIfNeeded() async {
    if (!AppConfig.isSupabaseConfigured || _database == null) return;

    try {
      final profiles = await _database!.query('profiles');
      final scores = await _database!.query('game_scores');

      // friend_code zorunlu; eksik olanlara ata
      final profilesWithCodes = <Map<String, dynamic>>[];
      for (final row in profiles) {
        final map = Map<String, dynamic>.from(row);
        final code = map['friendCode'] as String?;
        if (code == null || !_friendCodePattern.hasMatch(code)) {
          map['friendCode'] = await _generateUniqueFriendCode();
          await _database!.update(
            'profiles',
            {'friendCode': map['friendCode']},
            where: 'id = ?',
            whereArgs: [map['id']],
          );
        }
        profilesWithCodes.add(map);
      }

      await _supabaseRepo
          .upsertProfilesFromSqlite(profilesWithCodes)
          .timeout(const Duration(seconds: 20));
      await _supabaseRepo
          .upsertScoresFromSqlite(scores)
          .timeout(const Duration(seconds: 20));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_migrationPrefKey, true);
      _migrationComplete = true;

      debugPrint(
        'SQLite → Supabase migration completed: '
        '${profilesWithCodes.length} profiles, ${scores.length} scores',
      );
    } catch (e) {
      debugPrint('SQLite → Supabase migration failed: $e');
    }
  }

  // Veritabanı dosya yolunu al (TablePlus için)
  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    debugPrint('Database path: $path');
    return path;
  }

  // Veritabanı istatistiklerini al
  Future<Map<String, dynamic>> getDatabaseStats() async {
    if (_useSupabase) {
      try {
        return await _supabaseRepo.getStats();
      } catch (e) {
        debugPrint('Error getting Supabase stats: $e');
        return {
          'profilesCount': 0,
          'scoresCount': 0,
          'databasePath': AppConfig.supabaseUrl,
          'storageType': 'supabase',
          'migrationComplete': _migrationComplete,
          'usingSupabase': _useSupabase,
        };
      }
    }

    if (_database == null) {
      final dbPath = await getDatabasePath();
      return {
        'profilesCount': 0,
        'scoresCount': 0,
        'databasePath': dbPath,
        'storageType': 'sqlite',
        'migrationComplete': _migrationComplete,
        'usingSupabase': _useSupabase,
        'localSqliteProfiles': 0,
        'localSqliteScores': 0,
      };
    }

    try {
      final profilesCount =
          Sqflite.firstIntValue(
            await _database!.rawQuery('SELECT COUNT(*) FROM profiles'),
          ) ??
          0;

      final scoresCount =
          Sqflite.firstIntValue(
            await _database!.rawQuery('SELECT COUNT(*) FROM game_scores'),
          ) ??
          0;

      final dbPath = await getDatabasePath();

      return {
        'profilesCount': profilesCount,
        'scoresCount': scoresCount,
        'databasePath': dbPath,
        'storageType': 'sqlite',
        'migrationComplete': _migrationComplete,
        'usingSupabase': _useSupabase,
        'localSqliteProfiles': profilesCount,
        'localSqliteScores': scoresCount,
      };
    } catch (e) {
      debugPrint('Error getting database stats: $e');
      final dbPath = await getDatabasePath();
      return {
        'profilesCount': 0,
        'scoresCount': 0,
        'databasePath': dbPath,
        'storageType': 'sqlite',
        'migrationComplete': _migrationComplete,
        'usingSupabase': _useSupabase,
        'localSqliteProfiles': 0,
        'localSqliteScores': 0,
      };
    }
  }

  // Veritabanını sıfırla (debug için)
  Future<void> resetDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    // Veritabanı dosyasını sil
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Database file deleted');
      }
    } catch (e) {
      debugPrint('Error deleting database file: $e');
    }

    // Yeniden initialize et
    _isInitialized = false;
    _isInitializing = false;
    _initCompleter = null;
    await _initialize();
  }

  // Veritabanını başlat
  Future<void> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _dbName);

      debugPrint('Initializing database at: $path');
      debugPrint('Database version: $_dbVersion');

      _database = await openDatabase(
        path,
        version: _dbVersion,
        onCreate: (db, version) async {
          debugPrint('Creating database tables...');
          // Profiller tablosu
          await db.execute('''
            CREATE TABLE profiles (
              id TEXT PRIMARY KEY,
              email TEXT NOT NULL UNIQUE,
              firstName TEXT NOT NULL,
              lastName TEXT NOT NULL,
              birthDate TEXT NOT NULL,
              avatarPath TEXT,
              coverImagePath TEXT,
              displayName TEXT,
              avatarColor INTEGER,
              coverImageColor INTEGER,
              createdAt TEXT NOT NULL,
              lastPlayedAt TEXT,
              emailVerified INTEGER NOT NULL DEFAULT 0,
              passwordHash TEXT NOT NULL,
              friendCode TEXT NOT NULL UNIQUE
            )
          ''');

          // Skorlar tablosu
          await db.execute('''
            CREATE TABLE game_scores (
              id TEXT PRIMARY KEY,
              profileId TEXT NOT NULL,
              difficulty TEXT NOT NULL,
              score INTEGER NOT NULL,
              elapsedSeconds INTEGER NOT NULL,
              completedAt TEXT NOT NULL,
              isDailyGame INTEGER NOT NULL DEFAULT 0,
              FOREIGN KEY (profileId) REFERENCES profiles (id) ON DELETE CASCADE
            )
          ''');

          await db.execute('''
            CREATE TABLE friendships (
              id TEXT PRIMARY KEY,
              requesterId TEXT NOT NULL,
              addresseeId TEXT NOT NULL,
              status TEXT NOT NULL DEFAULT 'pending',
              createdAt TEXT NOT NULL,
              respondedAt TEXT,
              requesterSeenAt TEXT,
              addresseeSeenAt TEXT,
              FOREIGN KEY (requesterId) REFERENCES profiles (id) ON DELETE CASCADE,
              FOREIGN KEY (addresseeId) REFERENCES profiles (id) ON DELETE CASCADE
            )
          ''');

          // İndeksler
          await db.execute(
            'CREATE INDEX idx_profile_scores ON game_scores(profileId)',
          );
          await db.execute(
            'CREATE INDEX idx_score_date ON game_scores(completedAt)',
          );
          await db.execute('CREATE INDEX idx_email ON profiles(email)');
          await db.execute(
            'CREATE UNIQUE INDEX idx_friend_code ON profiles(friendCode)',
          );
          await db.execute(
            'CREATE INDEX idx_friendships_requester ON friendships(requesterId)',
          );
          await db.execute(
            'CREATE INDEX idx_friendships_addressee ON friendships(addresseeId)',
          );
          debugPrint('Database tables created successfully');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          debugPrint(
            'Upgrading database from version $oldVersion to $newVersion',
          );

          try {
            if (oldVersion < 2) {
              // Eski şemadan yeni şemaya geçiş (v1 -> v2)
              debugPrint('Migrating from v1 to v2...');
              await db.execute('ALTER TABLE profiles ADD COLUMN email TEXT');
              await db.execute(
                'ALTER TABLE profiles ADD COLUMN firstName TEXT',
              );
              await db.execute('ALTER TABLE profiles ADD COLUMN lastName TEXT');
              await db.execute(
                'ALTER TABLE profiles ADD COLUMN birthDate TEXT',
              );
              await db.execute(
                'ALTER TABLE profiles ADD COLUMN emailVerified INTEGER NOT NULL DEFAULT 0',
              );
              await db.execute(
                'CREATE INDEX IF NOT EXISTS idx_email ON profiles(email)',
              );
            }

            if (oldVersion < 3) {
              // v2 -> v3: name kolonunu kaldır, tabloyu yeniden oluştur
              debugPrint('Migrating from v2 to v3...');
            }

            if (oldVersion < 4) {
              // v3 -> v4: passwordHash kolonu ekle
              debugPrint('Migrating from v3 to v4...');
              try {
                await db.execute(
                  'ALTER TABLE profiles ADD COLUMN passwordHash TEXT NOT NULL DEFAULT \'\'',
                );
              } catch (e) {
                debugPrint('Error adding passwordHash column: $e');
                // Kolon zaten varsa veya tablo yoksa hata vermez
              }
            }

            if (oldVersion < 5) {
              // v4 -> v5: coverImagePath kolonu ekle
              debugPrint('Migrating from v4 to v5...');
              try {
                await db.execute(
                  'ALTER TABLE profiles ADD COLUMN coverImagePath TEXT',
                );
              } catch (e) {
                debugPrint('Error adding coverImagePath column: $e');
                // Kolon zaten varsa veya tablo yoksa hata vermez
              }
            }

            if (oldVersion < 6) {
              // v5 -> v6: displayName kolonu ekle
              debugPrint('Migrating from v5 to v6...');
              try {
                await db.execute(
                  'ALTER TABLE profiles ADD COLUMN displayName TEXT',
                );
              } catch (e) {
                debugPrint('Error adding displayName column: $e');
                // Kolon zaten varsa veya tablo yoksa hata vermez
              }
            }

            if (oldVersion < 7) {
              // v6 -> v7: coverImageColor kolonu ekle
              debugPrint('Migrating from v6 to v7...');
              try {
                await db.execute(
                  'ALTER TABLE profiles ADD COLUMN coverImageColor INTEGER',
                );
              } catch (e) {
                debugPrint('Error adding coverImageColor column: $e');
                // Kolon zaten varsa veya tablo yoksa hata vermez
              }
            }

            if (oldVersion < 8) {
              debugPrint(
                'Migrating from v7 to v8 (friendCode + friendships)...',
              );
              try {
                await db.execute(
                  "ALTER TABLE profiles ADD COLUMN friendCode TEXT NOT NULL DEFAULT ''",
                );
              } catch (e) {
                debugPrint('Error adding friendCode column: $e');
              }

              await db.execute('''
                CREATE TABLE IF NOT EXISTS friendships (
                  id TEXT PRIMARY KEY,
                  requesterId TEXT NOT NULL,
                  addresseeId TEXT NOT NULL,
                  createdAt TEXT NOT NULL,
                  FOREIGN KEY (requesterId) REFERENCES profiles (id) ON DELETE CASCADE,
                  FOREIGN KEY (addresseeId) REFERENCES profiles (id) ON DELETE CASCADE
                )
              ''');
              await db.execute(
                'CREATE INDEX IF NOT EXISTS idx_friendships_requester ON friendships(requesterId)',
              );
              await db.execute(
                'CREATE INDEX IF NOT EXISTS idx_friendships_addressee ON friendships(addresseeId)',
              );

              final rows = await db.query(
                'profiles',
                columns: ['id', 'friendCode'],
              );
              final usedCodes = <String>{};
              for (final row in rows) {
                final existing = row['friendCode'] as String? ?? '';
                final isUniqueValid =
                    _friendCodePattern.hasMatch(existing) &&
                    rows
                            .where(
                              (r) => (r['friendCode'] as String?) == existing,
                            )
                            .length ==
                        1;
                if (isUniqueValid) {
                  usedCodes.add(existing);
                  continue;
                }
                String code;
                do {
                  code = _randomFriendCode();
                } while (usedCodes.contains(code));
                usedCodes.add(code);
                await db.update(
                  'profiles',
                  {'friendCode': code},
                  where: 'id = ?',
                  whereArgs: [row['id']],
                );
              }

              try {
                await db.execute(
                  'CREATE UNIQUE INDEX IF NOT EXISTS idx_friend_code ON profiles(friendCode)',
                );
              } catch (e) {
                debugPrint('Error creating friendCode index: $e');
              }
            }

            if (oldVersion < 9) {
              debugPrint('Migrating from v8 to v9 (friend requests)...');
              await db.execute(
                "ALTER TABLE friendships ADD COLUMN status TEXT NOT NULL DEFAULT 'accepted'",
              );
              await db.execute(
                'ALTER TABLE friendships ADD COLUMN respondedAt TEXT',
              );
              await db.execute(
                'ALTER TABLE friendships ADD COLUMN requesterSeenAt TEXT',
              );
              await db.execute(
                'ALTER TABLE friendships ADD COLUMN addresseeSeenAt TEXT',
              );
              await db.execute(
                '''
                UPDATE friendships
                SET respondedAt = createdAt,
                    requesterSeenAt = createdAt,
                    addresseeSeenAt = createdAt
                WHERE status = ?
                ''',
                [FriendshipStatus.accepted.name],
              );
            }

            if (oldVersion < 3) {
              // v2 -> v3 migration devam ediyor

              // Önce tablonun var olup olmadığını kontrol et
              final tables = await db.rawQuery(
                "SELECT name FROM sqlite_master WHERE type='table' AND name='profiles'",
              );

              if (tables.isNotEmpty) {
                // Mevcut verileri yedekle
                final List<Map<String, dynamic>> oldData = await db.query(
                  'profiles',
                );

                // Eski tabloyu sil
                await db.execute('DROP TABLE IF EXISTS profiles_backup');
                await db.execute(
                  'ALTER TABLE profiles RENAME TO profiles_backup',
                );

                // Yeni tabloyu oluştur
                await db.execute('''
                  CREATE TABLE profiles (
                    id TEXT PRIMARY KEY,
                    email TEXT NOT NULL UNIQUE,
                    firstName TEXT NOT NULL,
                    lastName TEXT NOT NULL,
                    birthDate TEXT NOT NULL,
                    avatarPath TEXT,
                    avatarColor INTEGER,
                    createdAt TEXT NOT NULL,
                    lastPlayedAt TEXT,
                    emailVerified INTEGER NOT NULL DEFAULT 0,
                    passwordHash TEXT NOT NULL DEFAULT ''
                  )
                ''');

                // İndeksleri oluştur
                await db.execute(
                  'CREATE INDEX IF NOT EXISTS idx_email ON profiles(email)',
                );

                // Verileri yeni tabloya taşı
                for (var row in oldData) {
                  // Eski name değerini firstName ve lastName'e böl
                  String firstName = '';
                  String lastName = '';
                  if (row['name'] != null) {
                    final nameParts = (row['name'] as String).split(' ');
                    if (nameParts.isNotEmpty) {
                      firstName = nameParts[0];
                      if (nameParts.length > 1) {
                        lastName = nameParts.sublist(1).join(' ');
                      }
                    }
                  }

                  // Email yoksa placeholder ekle
                  String email =
                      row['email'] ?? 'user_${row['id']}@pandoku.local';

                  // BirthDate yoksa varsayılan değer
                  String birthDate =
                      row['birthDate'] ?? DateTime.now().toIso8601String();

                  await db.insert('profiles', {
                    'id': row['id'],
                    'email': email,
                    'firstName': firstName.isEmpty ? 'User' : firstName,
                    'lastName': lastName.isEmpty ? 'Name' : lastName,
                    'birthDate': birthDate,
                    'avatarPath': row['avatarPath'],
                    'coverImagePath': row['coverImagePath'],
                    'displayName': row['displayName'],
                    'avatarColor': row['avatarColor'],
                    'coverImageColor': row['coverImageColor'],
                    'createdAt': row['createdAt'],
                    'lastPlayedAt': row['lastPlayedAt'],
                    'emailVerified': row['emailVerified'] ?? 0,
                    'passwordHash': row['passwordHash'] ?? '',
                  });
                }

                // Backup tablosunu sil
                await db.execute('DROP TABLE IF EXISTS profiles_backup');
              } else {
                // Tablo yoksa yeni oluştur
                await db.execute('''
                  CREATE TABLE profiles (
                    id TEXT PRIMARY KEY,
                    email TEXT NOT NULL UNIQUE,
                    firstName TEXT NOT NULL,
                    lastName TEXT NOT NULL,
                    birthDate TEXT NOT NULL,
                    avatarPath TEXT,
                    avatarColor INTEGER,
                    createdAt TEXT NOT NULL,
                    lastPlayedAt TEXT,
                    emailVerified INTEGER NOT NULL DEFAULT 0,
                    passwordHash TEXT NOT NULL DEFAULT ''
                  )
                ''');
                await db.execute(
                  'CREATE INDEX IF NOT EXISTS idx_email ON profiles(email)',
                );
              }
            }

            debugPrint('Database upgrade completed successfully');
          } catch (e) {
            debugPrint('Error during database upgrade: $e');
            rethrow;
          }
        },
      );

      // Tablonun var olduğunu kontrol et, yoksa oluştur
      final tables = await _database!.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='profiles'",
      );

      if (tables.isEmpty) {
        debugPrint('Profiles table not found, creating...');
        // Tablo yoksa oluştur
        await _database!.execute('''
          CREATE TABLE IF NOT EXISTS profiles (
            id TEXT PRIMARY KEY,
            email TEXT NOT NULL UNIQUE,
            firstName TEXT NOT NULL,
            lastName TEXT NOT NULL,
            birthDate TEXT NOT NULL,
            avatarPath TEXT,
            avatarColor INTEGER,
            createdAt TEXT NOT NULL,
            lastPlayedAt TEXT,
            emailVerified INTEGER NOT NULL DEFAULT 0
          )
        ''');

        // game_scores tablosunu da kontrol et
        final scoresTables = await _database!.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='game_scores'",
        );

        if (scoresTables.isEmpty) {
          await _database!.execute('''
            CREATE TABLE IF NOT EXISTS game_scores (
              id TEXT PRIMARY KEY,
              profileId TEXT NOT NULL,
              difficulty TEXT NOT NULL,
              score INTEGER NOT NULL,
              elapsedSeconds INTEGER NOT NULL,
              completedAt TEXT NOT NULL,
              isDailyGame INTEGER NOT NULL DEFAULT 0,
              FOREIGN KEY (profileId) REFERENCES profiles (id) ON DELETE CASCADE
            )
          ''');
        }

        // İndeksleri oluştur
        await _database!.execute(
          'CREATE INDEX IF NOT EXISTS idx_profile_scores ON game_scores(profileId)',
        );
        await _database!.execute(
          'CREATE INDEX IF NOT EXISTS idx_score_date ON game_scores(completedAt)',
        );
        await _database!.execute(
          'CREATE INDEX IF NOT EXISTS idx_email ON profiles(email)',
        );

        debugPrint('Tables created successfully');
      }

      debugPrint('Database initialized successfully');
    } catch (e) {
      debugPrint('Error initializing database: $e');
      _database = null;
      rethrow;
    }
  }

  // Mevcut profili yükle
  Future<void> _loadCurrentProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileId = prefs.getString('current_profile_id');
      final isGuest = prefs.getBool('is_guest_mode') ?? true;

      if (profileId != null && !isGuest) {
        _currentProfile = await _fetchProfileById(profileId);
        _isGuestMode = _currentProfile == null;
      } else {
        _currentProfile = null;
        _isGuestMode = true;
      }
    } catch (e) {
      _currentProfile = null;
      _isGuestMode = true;
    }
  }

  // Mevcut profili kaydet
  Future<void> _saveCurrentProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentProfile != null && !_isGuestMode) {
      await prefs.setString('current_profile_id', _currentProfile!.id);
      await prefs.setBool('is_guest_mode', false);
    } else {
      await prefs.setBool('is_guest_mode', true);
      await prefs.remove('current_profile_id');
    }
  }

  // Email ile profil getir
  Future<UserProfile?> getProfileByEmail(String email) async {
    await ensureInitialized();

    if (_useSupabase) {
      return _supabaseRepo.getProfileByEmail(email);
    }

    if (_database == null) return null;

    final List<Map<String, dynamic>> maps = await _database!.query(
      'profiles',
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );

    if (maps.isEmpty) return null;

    return _mapToProfile(maps[0]);
  }

  // Profil getir (ID ile) — init sırasında deadlock olmaması için ayrı helper
  Future<UserProfile?> _fetchProfileById(String profileId) async {
    if (_useSupabase) {
      return _supabaseRepo.getProfile(profileId);
    }

    if (_database == null) return null;

    final List<Map<String, dynamic>> maps = await _database!.query(
      'profiles',
      where: 'id = ?',
      whereArgs: [profileId],
    );

    if (maps.isEmpty) return null;

    return _mapToProfile(maps[0]);
  }

  // Profil getir (ID ile)
  Future<UserProfile?> getProfile(String profileId) async {
    await ensureInitialized();
    return _fetchProfileById(profileId);
  }

  // Veritabanı map'ini UserProfile'a çevir
  UserProfile _mapToProfile(Map<String, dynamic> map) {
    // Eski veriler için null kontrolü
    if (map['email'] == null) {
      throw Exception('Profile data is outdated. Please re-register.');
    }

    return UserProfile.fromJson({
      'id': map['id'],
      'email': map['email'] ?? '',
      'firstName': map['firstName'] ?? map['name'] ?? '',
      'lastName': map['lastName'] ?? '',
      'birthDate': map['birthDate'] ?? DateTime.now().toIso8601String(),
      'avatarPath': map['avatarPath'],
      'coverImagePath': map['coverImagePath'],
      'displayName': map['displayName'],
      'avatarColor': map['avatarColor'],
      'coverImageColor': map['coverImageColor'],
      'createdAt': map['createdAt'],
      'lastPlayedAt': map['lastPlayedAt'],
      'emailVerified': (map['emailVerified'] as int? ?? 0) == 1,
      'passwordHash': map['passwordHash'] ?? '',
      'friendCode': map['friendCode'] ?? '',
    });
  }

  static String _randomFriendCode() {
    return _random.nextInt(1000000).toString().padLeft(6, '0');
  }

  Future<bool> _isFriendCodeTaken(String code) async {
    if (_useSupabase) {
      return _supabaseRepo.isFriendCodeTaken(code);
    }
    if (_database == null) return false;
    final rows = await _database!.query(
      'profiles',
      columns: ['id'],
      where: 'friendCode = ?',
      whereArgs: [code],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<String> _generateUniqueFriendCode() async {
    for (var attempt = 0; attempt < 40; attempt++) {
      final code = _randomFriendCode();
      if (!await _isFriendCodeTaken(code)) return code;
    }
    throw Exception('Could not generate a unique friend code');
  }

  /// Eksik/geçersiz arkadaş kodunu tamamlar (mevcut oyuncular için).
  Future<void> ensureFriendCodeAssigned() async {
    final profile = _currentProfile;
    if (profile == null || _isGuestMode) return;
    if (profile.hasFriendCode) return;

    await ensureInitialized();
    final code = await _generateUniqueFriendCode();
    final updated = profile.copyWith(friendCode: code);

    if (_useSupabase) {
      await _supabaseRepo.updateFriendCode(profile.id, code);
    } else if (_database != null) {
      await _database!.update(
        'profiles',
        {'friendCode': code},
        where: 'id = ?',
        whereArgs: [profile.id],
      );
    }

    _currentProfile = updated;
    notifyListeners();
  }

  // Email doğrulama kodu gönder
  // Development için kod bilgisini de döndürüyoruz
  Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    final success = await _emailService.sendVerificationCode(email);
    // Development için kodu da döndürüyoruz
    final actualCode = await _emailService.getLastCode(email);
    return {'success': success, 'code': actualCode ?? ''};
  }

  // Email doğrulama kodunu kontrol et
  Future<bool> verifyEmailCode(String email, String code) async {
    return await _emailService.verifyCode(email, code);
  }

  // Profil oluştur (email doğrulaması ile)
  Future<UserProfile> registerProfile({
    required String email,
    required String firstName,
    required String lastName,
    required DateTime birthDate,
    required String verificationCode,
    required String password,
    String? avatarPath,
    int? avatarColor,
  }) async {
    await ensureInitialized();
    if (!_useSupabase && _database == null) {
      throw Exception('Database not initialized');
    }

    // Email doğrulama kodunu kontrol et
    final isValidCode = await _emailService.verifyCode(email, verificationCode);
    if (!isValidCode) {
      throw Exception('Invalid verification code');
    }

    // Şifre kontrolü
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }

    // Zaten profil var mı kontrol et (tek profil kuralı)
    final existingProfile = await getProfileByEmail(email);
    if (existingProfile != null) {
      throw Exception('Profile already exists for this email');
    }

    // Şifreyi hash'le
    final passwordHash = _hashPassword(password);
    final friendCode = await _generateUniqueFriendCode();

    // Yeni profil oluştur
    final profile = UserProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email.toLowerCase(),
      firstName: firstName,
      lastName: lastName,
      birthDate: birthDate,
      avatarPath: avatarPath,
      avatarColor: avatarColor,
      createdAt: DateTime.now(),
      emailVerified: true,
      passwordHash: passwordHash,
      friendCode: friendCode,
    );

    if (_useSupabase) {
      await _supabaseRepo.insertProfile(profile);
    } else {
      await _database!.insert('profiles', {
        ...profile.toJson(),
        'emailVerified': 1, // SQLite boolean için 1/0
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Profili aktif yap
    await login(email, password);
    await OnboardingManager.scheduleHomeGuide();

    return profile;
  }

  // Email ve şifre ile giriş yap
  Future<UserProfile> login(String email, String password) async {
    await ensureInitialized();
    if (!_useSupabase && _database == null) {
      throw Exception('Database not initialized');
    }

    final profile = await getProfileByEmail(email);
    if (profile == null) {
      throw Exception('Profile not found');
    }

    // Şifre kontrolü
    if (!_verifyPassword(password, profile.passwordHash)) {
      throw Exception('Invalid password');
    }

    _currentProfile = profile;
    _isGuestMode = false;
    await _saveCurrentProfile();
    try {
      await ensureFriendCodeAssigned();
    } catch (e) {
      debugPrint('Friend code assignment deferred: $e');
    }
    notifyListeners();

    return _currentProfile!;
  }

  // Çıkış yap
  Future<void> logout() async {
    _currentProfile = null;
    _isGuestMode = true;
    await _saveCurrentProfile();
    notifyListeners();
  }

  // Profil sil
  Future<void> deleteProfile(String profileId) async {
    await ensureInitialized();

    if (_useSupabase) {
      await _supabaseRepo.deleteProfile(profileId);
    } else {
      if (_database == null) return;

      await _database!.delete(
        'profiles',
        where: 'id = ?',
        whereArgs: [profileId],
      );

      await _database!.delete(
        'game_scores',
        where: 'profileId = ?',
        whereArgs: [profileId],
      );
    }

    if (_currentProfile?.id == profileId) {
      _currentProfile = null;
      _isGuestMode = true;
      await _saveCurrentProfile();
      notifyListeners();
    }
  }

  // Profil güncelle
  Future<void> updateProfile(UserProfile profile) async {
    await ensureInitialized();

    if (_useSupabase) {
      await _supabaseRepo.updateProfile(profile);
    } else {
      if (_database == null) return;

      await _database!.update(
        'profiles',
        {...profile.toJson(), 'emailVerified': profile.emailVerified ? 1 : 0},
        where: 'id = ?',
        whereArgs: [profile.id],
      );
    }

    if (_currentProfile?.id == profile.id) {
      _currentProfile = profile;
      notifyListeners();
    }
  }

  // Son oynama zamanını güncelle
  Future<void> updateLastPlayed(String profileId) async {
    await ensureInitialized();
    final now = DateTime.now();

    if (_useSupabase) {
      await _supabaseRepo.updateLastPlayed(profileId, now);
    } else {
      if (_database == null) return;

      await _database!.update(
        'profiles',
        {'lastPlayedAt': now.toIso8601String()},
        where: 'id = ?',
        whereArgs: [profileId],
      );
    }

    if (_currentProfile?.id == profileId) {
      _currentProfile = _currentProfile!.copyWith(lastPlayedAt: now);
      notifyListeners();
    }
  }

  // Skor kaydet
  Future<void> saveScore(GameScore score) async {
    if (_isGuestMode || _currentProfile == null) return;

    await ensureInitialized();

    try {
      if (_useSupabase) {
        await _supabaseRepo.saveScore(score);
      } else {
        if (_database == null) return;

        await _database!.insert('game_scores', {
          ...score.toJson(),
          'isDailyGame': score.isDailyGame ? 1 : 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await updateLastPlayed(_currentProfile!.id);
    } catch (e) {
      debugPrint('Error saving score: $e');
      rethrow;
    }
  }

  // Profil skorlarını getir
  Future<List<GameScore>> getProfileScores(
    String profileId, {
    String? difficulty,
  }) async {
    await ensureInitialized();

    if (_useSupabase) {
      return _supabaseRepo.getProfileScores(profileId, difficulty: difficulty);
    }

    if (_database == null) return [];

    String where = 'profileId = ?';
    List<dynamic> whereArgs = [profileId];

    if (difficulty != null) {
      where += ' AND difficulty = ?';
      whereArgs.add(difficulty);
    }

    final List<Map<String, dynamic>> maps = await _database!.query(
      'game_scores',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'completedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return GameScore.fromJson({
        'id': maps[i]['id'],
        'profileId': maps[i]['profileId'],
        'difficulty': maps[i]['difficulty'],
        'score': maps[i]['score'],
        'elapsedSeconds': maps[i]['elapsedSeconds'],
        'completedAt': maps[i]['completedAt'],
        'isDailyGame': maps[i]['isDailyGame'] == 1,
      });
    });
  }

  // Mevcut profili veritabanından yenile
  Future<void> refreshCurrentProfile() async {
    await ensureInitialized();
    final profileId = _currentProfile?.id;
    if (profileId == null || _isGuestMode) return;

    try {
      final fresh = await _fetchProfileById(profileId);
      if (fresh != null) {
        _currentProfile = fresh;
        try {
          await ensureFriendCodeAssigned();
        } catch (e) {
          debugPrint('Friend code assignment deferred: $e');
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing profile: $e');
    }
  }

  // Profil istatistiklerini getir (zorluk bazında ayrılmış)
  Future<ProfileStats> getProfileStats(String profileId) async {
    await ensureInitialized();

    final scores = await getProfileScores(profileId);
    if (scores.isEmpty) return ProfileStats.empty();

    return ProfileStats.fromScores(scores);
  }

  Future<UserProfile?> getProfileByFriendCode(String friendCode) async {
    await ensureInitialized();
    final code = friendCode.trim();
    if (!_friendCodePattern.hasMatch(code)) return null;

    if (_useSupabase) {
      return _supabaseRepo.getProfileByFriendCode(code);
    }
    if (_database == null) return null;

    final maps = await _database!.query(
      'profiles',
      where: 'friendCode = ?',
      whereArgs: [code],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return _mapToProfile(maps.first);
  }

  Future<bool> areFriends(String profileIdA, String profileIdB) async {
    await ensureInitialized();
    if (_useSupabase) {
      return _supabaseRepo.areFriends(profileIdA, profileIdB);
    }
    if (_database == null) return false;

    final maps = await _database!.query(
      'friendships',
      where:
          '(requesterId = ? AND addresseeId = ?) OR (requesterId = ? AND addresseeId = ?)',
      whereArgs: [profileIdA, profileIdB, profileIdB, profileIdA],
      limit: 1,
    );
    return maps.any((row) => row['status'] == FriendshipStatus.accepted.name);
  }

  Future<Friendship?> _getRelationship(
    String profileIdA,
    String profileIdB,
  ) async {
    if (_useSupabase) {
      return _supabaseRepo.getRelationship(profileIdA, profileIdB);
    }
    if (_database == null) return null;
    final maps = await _database!.query(
      'friendships',
      where:
          '(requesterId = ? AND addresseeId = ?) OR (requesterId = ? AND addresseeId = ?)',
      whereArgs: [profileIdA, profileIdB, profileIdB, profileIdA],
      limit: 1,
    );
    return maps.isEmpty ? null : Friendship.fromJson(maps.first);
  }

  /// Arkadaş kodu ile istek gönderir. Başarılıysa hedef profili döner.
  Future<UserProfile> addFriendByCode(String friendCode) async {
    await ensureInitialized();
    await ensureFriendCodeAssigned();

    final me = _currentProfile;
    if (me == null || _isGuestMode) {
      throw Exception('Not logged in');
    }

    final code = friendCode.trim();
    if (!_friendCodePattern.hasMatch(code)) {
      throw Exception('Invalid friend code');
    }

    if (me.friendCode == code) {
      throw Exception('Cannot add yourself');
    }

    final other = await getProfileByFriendCode(code);
    if (other == null) {
      throw Exception('Friend code not found');
    }

    final relationship = await _getRelationship(me.id, other.id);
    if (relationship != null) {
      if (relationship.status == FriendshipStatus.accepted) {
        throw Exception('Already friends');
      }
      throw Exception('Friend request already exists');
    }

    final friendship = Friendship(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      requesterId: me.id,
      addresseeId: other.id,
      status: FriendshipStatus.pending,
      createdAt: DateTime.now(),
    );

    if (_useSupabase) {
      await _supabaseRepo.insertFriendship(friendship);
    } else {
      if (_database == null) throw Exception('Database not initialized');
      await _database!.insert('friendships', {
        'id': friendship.id,
        'requesterId': friendship.requesterId,
        'addresseeId': friendship.addresseeId,
        'status': friendship.status.name,
        'createdAt': friendship.createdAt.toIso8601String(),
        'respondedAt': null,
        'requesterSeenAt': null,
        'addresseeSeenAt': null,
      });
    }

    notifyListeners();
    return other;
  }

  Future<List<UserProfile>> getFriends() async {
    await ensureInitialized();
    final me = _currentProfile;
    if (me == null || _isGuestMode) return [];

    try {
      late final List<Friendship> friendships;
      if (_useSupabase) {
        friendships = await _supabaseRepo.getFriendships(me.id);
      } else {
        if (_database == null) return [];
        final maps = await _database!.query(
          'friendships',
          where: '(requesterId = ? OR addresseeId = ?) AND status = ?',
          whereArgs: [me.id, me.id, FriendshipStatus.accepted.name],
          orderBy: 'createdAt DESC',
        );
        friendships = maps
            .map(
              (m) => Friendship.fromJson({
                'id': m['id'],
                'requesterId': m['requesterId'],
                'addresseeId': m['addresseeId'],
                'status': m['status'],
                'createdAt': m['createdAt'],
                'respondedAt': m['respondedAt'],
                'requesterSeenAt': m['requesterSeenAt'],
                'addresseeSeenAt': m['addresseeSeenAt'],
              }),
            )
            .toList();
      }

      final friends = <UserProfile>[];
      for (final f in friendships) {
        final otherId = f.otherProfileId(me.id);
        final profile = await _fetchProfileById(otherId);
        if (profile != null) friends.add(profile);
      }
      return friends;
    } catch (e) {
      debugPrint('Error loading friends: $e');
      rethrow;
    }
  }

  Future<List<FriendNotification>> getFriendNotifications() async {
    await ensureInitialized();
    final me = _currentProfile;
    if (me == null || _isGuestMode) return [];

    late final List<Friendship> relationships;
    if (_useSupabase) {
      relationships = await _supabaseRepo.getFriendNotifications(me.id);
    } else {
      if (_database == null) return [];
      final rows = await _database!.query(
        'friendships',
        where:
            '(addresseeId = ? AND status = ?) OR '
            '(requesterId = ? AND status = ?) OR '
            '(addresseeId = ? AND status = ?)',
        whereArgs: [
          me.id,
          FriendshipStatus.pending.name,
          me.id,
          FriendshipStatus.accepted.name,
          me.id,
          FriendshipStatus.accepted.name,
        ],
        orderBy: 'createdAt DESC',
      );
      relationships = rows.map(Friendship.fromJson).toList();
    }

    final notifications = <FriendNotification>[];
    for (final relationship in relationships) {
      final otherId = relationship.otherProfileId(me.id);
      final profile = await _fetchProfileById(otherId);
      if (profile == null) continue;
      final isIncoming = relationship.addresseeId == me.id;
      notifications.add(
        FriendNotification(
          friendship: relationship,
          isIncoming: isIncoming,
          isUnread: isIncoming
              ? relationship.addresseeSeenAt == null
              : relationship.requesterSeenAt == null,
          otherProfile: UserProfileSummary(
            id: profile.id,
            name: profile.personalName,
            avatarPath: profile.avatarPath,
            avatarColor: profile.avatarColor,
          ),
        ),
      );
    }
    return notifications;
  }

  Future<int> getUnreadFriendNotificationCount() async {
    await ensureInitialized();
    final me = _currentProfile;
    if (me == null || _isGuestMode) return 0;
    if (_useSupabase) {
      return _supabaseRepo.getUnreadFriendNotificationCount(me.id);
    }
    if (_database == null) return 0;
    final result = await _database!.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM friendships
      WHERE (addresseeId = ? AND status = ? AND addresseeSeenAt IS NULL)
         OR (requesterId = ? AND status = ? AND requesterSeenAt IS NULL)
      ''',
      [
        me.id,
        FriendshipStatus.pending.name,
        me.id,
        FriendshipStatus.accepted.name,
      ],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> markFriendNotificationsSeen() async {
    await ensureInitialized();
    final me = _currentProfile;
    if (me == null || _isGuestMode) return;
    final now = DateTime.now().toIso8601String();
    if (_useSupabase) {
      await _supabaseRepo.markFriendNotificationsSeen(me.id);
    } else if (_database != null) {
      await _database!.update(
        'friendships',
        {'addresseeSeenAt': now},
        where: 'addresseeId = ? AND status = ? AND addresseeSeenAt IS NULL',
        whereArgs: [me.id, FriendshipStatus.pending.name],
      );
      await _database!.update(
        'friendships',
        {'requesterSeenAt': now},
        where: 'requesterId = ? AND status = ? AND requesterSeenAt IS NULL',
        whereArgs: [me.id, FriendshipStatus.accepted.name],
      );
    }
    notifyListeners();
  }

  Future<void> acceptFriendRequest(String friendshipId) async {
    await ensureInitialized();
    final me = _currentProfile;
    if (me == null || _isGuestMode) return;
    if (_useSupabase) {
      await _supabaseRepo.acceptFriendRequest(friendshipId, me.id);
    } else if (_database != null) {
      final now = DateTime.now().toIso8601String();
      await _database!.update(
        'friendships',
        {
          'status': FriendshipStatus.accepted.name,
          'respondedAt': now,
          'requesterSeenAt': null,
          'addresseeSeenAt': now,
        },
        where: 'id = ? AND addresseeId = ? AND status = ?',
        whereArgs: [friendshipId, me.id, FriendshipStatus.pending.name],
      );
    }
    notifyListeners();
  }

  Future<void> rejectFriendRequest(String friendshipId) async {
    await ensureInitialized();
    final me = _currentProfile;
    if (me == null || _isGuestMode) return;
    if (_useSupabase) {
      await _supabaseRepo.rejectFriendRequest(friendshipId, me.id);
    } else if (_database != null) {
      await _database!.delete(
        'friendships',
        where: 'id = ? AND addresseeId = ? AND status = ?',
        whereArgs: [friendshipId, me.id, FriendshipStatus.pending.name],
      );
    }
    notifyListeners();
  }

  Future<void> removeFriend(String friendProfileId) async {
    await ensureInitialized();
    final me = _currentProfile;
    if (me == null || _isGuestMode) return;

    if (_useSupabase) {
      await _supabaseRepo.deleteFriendshipBetween(me.id, friendProfileId);
    } else if (_database != null) {
      await _database!.delete(
        'friendships',
        where:
            '(requesterId = ? AND addresseeId = ?) OR (requesterId = ? AND addresseeId = ?)',
        whereArgs: [me.id, friendProfileId, friendProfileId, me.id],
      );
    }

    notifyListeners();
  }

  // Veritabanını kapat
  Future<void> close() async {
    await _database?.close();
  }
}
