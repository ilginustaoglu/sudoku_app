import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_state_manager.dart';
import '../services/profile_manager.dart';
import '../services/sudoku_generator.dart';
import '../services/daily_game_manager.dart';
import '../models/sudoku_game.dart';
import 'game_page.dart';
import 'settings_page.dart';
import 'other_apps_page.dart';
import 'calendar_page.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'user_profile_display_page.dart';

class HomePage extends StatelessWidget {
  final GameStateManager gameStateManager;

  const HomePage({super.key, required this.gameStateManager});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        leading: IconButton(
          icon: const Icon(Icons.calendar_today, color: Color(0xFF2E7D32)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CalendarPage(
                  gameStateManager: gameStateManager,
                ),
              ),
            );
          },
        ),
        actions: [
          // Profil butonu (sadece giriş yapılmışsa göster)
          Consumer<ProfileManager>(
            builder: (context, profileManager, child) {
              // Sadece profil durumu değiştiğinde rebuild et
              if (!profileManager.isGuestMode && profileManager.currentProfile != null) {
                final avatarColor = profileManager.currentProfile?.avatarColor;
                return GestureDetector(
                  onTap: () {
                    // Profil sayfasına git
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserProfileDisplayPage(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: avatarColor != null
                          ? Color(avatarColor)
                          : Colors.grey.shade300,
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Bambu ikonu - Diğer uygulamalar
          IconButton(
            icon: Image.asset(
              'assets/images/bamboo.png',
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.eco, color: Color(0xFF2E7D32)); // Koyu yeşil
              },
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OtherAppsPage(),
                ),
              );
            },
          ),
          // Ayarlar çarkı (koyu yeşil)
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF2E7D32)), // Koyu yeşil
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                
                // Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/pandacover.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Logo yoksa geçici ikon göster
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF6F4E37), // Kahve rengi
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.grid_4x4,
                            size: 60,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Uygulama Adı
                const Text(
                  'Pandoku',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6F4E37), // Kahve rengi
                    letterSpacing: 1.2,
                  ),
                ),
                
                const Spacer(flex: 3),
                
                // Oyun durumuna göre butonlar
                Consumer<GameStateManager>(
                  builder: (context, manager, child) {
                    // Initialization constructor'da başlatılıyor (non-blocking)
                    if (manager.isLoading) {
                      return const CircularProgressIndicator();
                    }
                    if (manager.hasOngoingGame) {
                      // Devam eden oyun varsa Continue ve New Game
                      return Column(
                        children: [
                          _buildButton(
                            context,
                            'Continue',
                            Icons.play_arrow,
                            const Color(0xFF2E7D32), // Koyu yeşil
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GamePage(
                                    gameStateManager: gameStateManager,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildButton(
                            context,
                            'New Game',
                            Icons.refresh,
                            const Color(0xFF2E7D32), // Koyu yeşil
                            () {
                              _showDifficultyDialog(context);
                            },
                          ),
                        ],
                      );
                    } else {
                      // Yeni oyun için Play
                      return _buildButton(
                        context,
                        'Play',
                        Icons.play_arrow,
                        const Color(0xFF2E7D32), // Koyu yeşil
                        () {
                          _showDifficultyDialog(context);
                        },
                      );
                    }
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Bugünün Oyunu butonu
                _buildButton(
                  context,
                  'Today\'s Game',
                  Icons.today,
                  const Color(0xFF6F4E37), // Kahve rengi
                  () async {
                    final dailyGameManager = DailyGameManager();
                    final today = DateTime.now();
                    final game = await dailyGameManager.getDailyGame(today);
                    gameStateManager.startNewGame(game);
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GamePage(
                            gameStateManager: gameStateManager,
                          ),
                        ),
                      );
                    }
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Pandaccount butonu
                Consumer<ProfileManager>(
                  builder: (context, profileManager, child) {
                    if (profileManager.isGuestMode) {
                      return _buildButton(
                        context,
                        'Enter/Create via Pandaccount',
                        Icons.account_circle,
                        const Color(0xFF6F4E37), // Kahve rengi
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                          );
                        },
                      );
                    } else {
                      // Profil varsa sadece çıkış butonu göster
                      return _buildButton(
                        context,
                        'Logout',
                        Icons.logout,
                        Colors.red.shade300,
                        () async {
                          await profileManager.logout();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Logged out successfully'),
                              ),
                            );
                          }
                        },
                      );
                    }
                  },
                ),
                
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDifficultyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Select Difficulty Level'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDifficultyOption(
                dialogContext,
                'Easy',
                const Color(0xFF2E7D32), // Koyu yeşil
                () => _startNewGame(context, dialogContext, 'Easy'),
              ),
              const SizedBox(height: 12),
              _buildDifficultyOption(
                dialogContext,
                'Medium',
                Colors.orange,
                () => _startNewGame(context, dialogContext, 'Medium'),
              ),
              const SizedBox(height: 12),
              _buildDifficultyOption(
                dialogContext,
                'Hard',
                Colors.red,
                () => _startNewGame(context, dialogContext, 'Hard'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDifficultyOption(
    BuildContext context,
    String difficulty,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            difficulty,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  void _startNewGame(
    BuildContext context,
    BuildContext dialogContext,
    String difficulty,
  ) {
    Navigator.pop(dialogContext); // Dialog'u kapat

    // Yeni oyun oluştur
    SudokuGame newGame = SudokuGenerator.generateNewGame(difficulty: difficulty);
    gameStateManager.startNewGame(newGame);

    // Oyun sayfasına git
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GamePage(
          gameStateManager: gameStateManager,
        ),
      ),
    );
  }
}

