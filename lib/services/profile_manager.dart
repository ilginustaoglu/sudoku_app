import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../config/app_config.dart';
import '../models/user_profile.dart';
import '../models/game_score.dart';
import '../models/profile_stats.dart';
import 'onboarding_manager.dart';
import 'email_verification_service.dart';
import 'supabase_profile_repository.dart';

class ProfileManager extends ChangeNotifier {
  static const String _dbName = 'sudoku_profiles.db';
  static const int _dbVersion = 7; // Version artırıldı - coverImageColor kolonu eklendi
  static const String _migrationPrefKey = 'sqlite_migrated_to_supabase_v1';

  final EmailVerificationService _emailService = EmailVerificationService();
  final SupabaseProfileRepository _supabaseRepo = SupabaseProfileRepository();
  bool _migrationComplete = false;

  bool get _useSupabase =>
      AppConfig.isSupabaseConfigured && _migrationComplete;
  
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

      final needsSqlite = !AppConfig.isSupabaseConfigured || !_migrationComplete;
      if (needsSqlite) {
        await _initDatabase();
      }

      if (AppConfig.isSupabaseConfigured && !_migrationComplete) {
        await _migrateSqliteToSupabaseIfNeeded();
      }

      await _loadCurrentProfile();
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

      await _supabaseRepo
          .upsertProfilesFromSqlite(profiles)
          .timeout(const Duration(seconds: 20));
      await _supabaseRepo
          .upsertScoresFromSqlite(scores)
          .timeout(const Duration(seconds: 20));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_migrationPrefKey, true);
      _migrationComplete = true;

      debugPrint(
        'SQLite → Supabase migration completed: '
        '${profiles.length} profiles, ${scores.length} scores',
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
      final profilesCount = Sqflite.firstIntValue(
        await _database!.rawQuery('SELECT COUNT(*) FROM profiles')
      ) ?? 0;

      final scoresCount = Sqflite.firstIntValue(
        await _database!.rawQuery('SELECT COUNT(*) FROM game_scores')
      ) ?? 0;

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
              passwordHash TEXT NOT NULL
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

          // İndeksler
          await db.execute('CREATE INDEX idx_profile_scores ON game_scores(profileId)');
          await db.execute('CREATE INDEX idx_score_date ON game_scores(completedAt)');
          await db.execute('CREATE INDEX idx_email ON profiles(email)');
          debugPrint('Database tables created successfully');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          debugPrint('Upgrading database from version $oldVersion to $newVersion');
          
          try {
            if (oldVersion < 2) {
              // Eski şemadan yeni şemaya geçiş (v1 -> v2)
              debugPrint('Migrating from v1 to v2...');
              await db.execute('ALTER TABLE profiles ADD COLUMN email TEXT');
              await db.execute('ALTER TABLE profiles ADD COLUMN firstName TEXT');
              await db.execute('ALTER TABLE profiles ADD COLUMN lastName TEXT');
              await db.execute('ALTER TABLE profiles ADD COLUMN birthDate TEXT');
              await db.execute('ALTER TABLE profiles ADD COLUMN emailVerified INTEGER NOT NULL DEFAULT 0');
              await db.execute('CREATE INDEX IF NOT EXISTS idx_email ON profiles(email)');
            }
            
            if (oldVersion < 3) {
              // v2 -> v3: name kolonunu kaldır, tabloyu yeniden oluştur
              debugPrint('Migrating from v2 to v3...');
            }
            
            if (oldVersion < 4) {
              // v3 -> v4: passwordHash kolonu ekle
              debugPrint('Migrating from v3 to v4...');
              try {
                await db.execute('ALTER TABLE profiles ADD COLUMN passwordHash TEXT NOT NULL DEFAULT \'\'');
              } catch (e) {
                debugPrint('Error adding passwordHash column: $e');
                // Kolon zaten varsa veya tablo yoksa hata vermez
              }
            }
            
            if (oldVersion < 5) {
              // v4 -> v5: coverImagePath kolonu ekle
              debugPrint('Migrating from v4 to v5...');
              try {
                await db.execute('ALTER TABLE profiles ADD COLUMN coverImagePath TEXT');
              } catch (e) {
                debugPrint('Error adding coverImagePath column: $e');
                // Kolon zaten varsa veya tablo yoksa hata vermez
              }
            }
            
            if (oldVersion < 6) {
              // v5 -> v6: displayName kolonu ekle
              debugPrint('Migrating from v5 to v6...');
              try {
                await db.execute('ALTER TABLE profiles ADD COLUMN displayName TEXT');
              } catch (e) {
                debugPrint('Error adding displayName column: $e');
                // Kolon zaten varsa veya tablo yoksa hata vermez
              }
            }
            
            if (oldVersion < 7) {
              // v6 -> v7: coverImageColor kolonu ekle
              debugPrint('Migrating from v6 to v7...');
              try {
                await db.execute('ALTER TABLE profiles ADD COLUMN coverImageColor INTEGER');
              } catch (e) {
                debugPrint('Error adding coverImageColor column: $e');
                // Kolon zaten varsa veya tablo yoksa hata vermez
              }
            }
            
            if (oldVersion < 3) {
              // v2 -> v3 migration devam ediyor
              
              // Önce tablonun var olup olmadığını kontrol et
              final tables = await db.rawQuery(
                "SELECT name FROM sqlite_master WHERE type='table' AND name='profiles'"
              );
              
              if (tables.isNotEmpty) {
                // Mevcut verileri yedekle
                final List<Map<String, dynamic>> oldData = await db.query('profiles');
                
                // Eski tabloyu sil
                await db.execute('DROP TABLE IF EXISTS profiles_backup');
                await db.execute('ALTER TABLE profiles RENAME TO profiles_backup');
                
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
                await db.execute('CREATE INDEX IF NOT EXISTS idx_email ON profiles(email)');
                
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
                  String email = row['email'] ?? 'user_${row['id']}@pandoku.local';
                  
                  // BirthDate yoksa varsayılan değer
                  String birthDate = row['birthDate'] ?? DateTime.now().toIso8601String();
                  
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
                await db.execute('CREATE INDEX IF NOT EXISTS idx_email ON profiles(email)');
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
        "SELECT name FROM sqlite_master WHERE type='table' AND name='profiles'"
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
          "SELECT name FROM sqlite_master WHERE type='table' AND name='game_scores'"
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
        await _database!.execute('CREATE INDEX IF NOT EXISTS idx_profile_scores ON game_scores(profileId)');
        await _database!.execute('CREATE INDEX IF NOT EXISTS idx_score_date ON game_scores(completedAt)');
        await _database!.execute('CREATE INDEX IF NOT EXISTS idx_email ON profiles(email)');
        
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
    });
  }

  // Email doğrulama kodu gönder
  // Development için kod bilgisini de döndürüyoruz
  Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    final success = await _emailService.sendVerificationCode(email);
    // Development için kodu da döndürüyoruz
    final actualCode = await _emailService.getLastCode(email);
    return {
      'success': success,
      'code': actualCode ?? '',
    };
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
    );

    if (_useSupabase) {
      await _supabaseRepo.insertProfile(profile);
    } else {
      await _database!.insert(
        'profiles',
        {
          ...profile.toJson(),
          'emailVerified': 1, // SQLite boolean için 1/0
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
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
    notifyListeners();

    return profile;
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
        {
          ...profile.toJson(),
          'emailVerified': profile.emailVerified ? 1 : 0,
        },
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

        await _database!.insert(
          'game_scores',
          {
            ...score.toJson(),
            'isDailyGame': score.isDailyGame ? 1 : 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await updateLastPlayed(_currentProfile!.id);
    } catch (e) {
      debugPrint('Error saving score: $e');
      rethrow;
    }
  }

  // Profil skorlarını getir
  Future<List<GameScore>> getProfileScores(String profileId, {String? difficulty}) async {
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

  // Veritabanını kapat
  Future<void> close() async {
    await _database?.close();
  }
}
