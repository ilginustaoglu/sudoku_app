import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

void main() async {
  print('=' * 60);
  print('SQLite Database Information');
  print('=' * 60);
  
  try {
    // Veritabanı yolunu al
    final dbPath = await getDatabasesPath();
    final dbName = 'sudoku_profiles.db';
    final fullPath = path.join(dbPath, dbName);
    
    print('\n📁 Database Name: $dbName');
    print('📂 Database Path: $fullPath');
    
    // Dosya var mı kontrol et
    final file = File(fullPath);
    if (await file.exists()) {
      final fileSize = await file.length();
      print('✅ Database file exists');
      print('📊 File Size: ${(fileSize / 1024).toStringAsFixed(2)} KB');
      
      // Veritabanına bağlan ve istatistikleri al
      try {
        final db = await openDatabase(fullPath, readOnly: true);
        
        // Profil sayısı
        final profilesCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM profiles')
        ) ?? 0;
        
        // Skor sayısı
        final scoresCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM game_scores')
        ) ?? 0;
        
        print('\n📈 Database Statistics:');
        print('   👤 Profiles: $profilesCount');
        print('   🎮 Game Scores: $scoresCount');
        
        // Profilleri listele
        if (profilesCount > 0) {
          print('\n👥 Profiles:');
          final profiles = await db.query('profiles', 
            columns: ['id', 'email', 'firstName', 'lastName', 'createdAt'],
            orderBy: 'createdAt DESC'
          );
          
          for (var profile in profiles) {
            print('   - ${profile['email']} (${profile['firstName']} ${profile['lastName']})');
          }
        }
        
        await db.close();
      } catch (e) {
        print('⚠️  Could not read database: $e');
        print('   (Database might be locked or corrupted)');
      }
    } else {
      print('❌ Database file does not exist yet');
      print('   Run the app first to create the database');
    }
    
    print('\n' + '=' * 60);
    print('📋 To connect in TablePlus:');
    print('   1. Open TablePlus');
    print('   2. Click "Create a new connection"');
    print('   3. Select "SQLite"');
    print('   4. Paste this path:');
    print('      $fullPath');
    print('   5. Click "Connect"');
    print('=' * 60);
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
