import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_state_manager.dart';
import '../services/sudoku_generator.dart';
import '../models/sudoku_game.dart';
import 'game_page.dart';
import 'settings_page.dart';
import 'theme_selection_page.dart';
import 'other_apps_page.dart';

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
        actions: [
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
                            const Color(0xFF6F4E37), // Kahve rengi
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
                        const Color(0xFF6F4E37), // Kahve rengi
                        () {
                          _showDifficultyDialog(context);
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

