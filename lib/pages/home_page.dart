import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_state_manager.dart';
import '../services/profile_manager.dart';
import '../services/sudoku_generator.dart';
import '../services/daily_game_manager.dart';
import '../services/onboarding_manager.dart';
import '../models/sudoku_game.dart';
import '../l10n/app_localizations.dart';
import '../widgets/spotlight_guide.dart';
import 'game_page.dart';
import 'settings_page.dart';
import 'other_apps_page.dart';
import 'calendar_page.dart';
import 'user_profile_display_page.dart';
import 'feedback_page.dart';

class HomePage extends StatefulWidget {
  final GameStateManager gameStateManager;

  const HomePage({super.key, required this.gameStateManager});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _playKey = GlobalKey();
  final _dailyKey = GlobalKey();
  final _calendarKey = GlobalKey();
  final _profileKey = GlobalKey();
  final _feedbackKey = GlobalKey();
  final _settingsKey = GlobalKey();
  bool _guideChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowGuide());
  }

  Future<void> _maybeShowGuide() async {
    if (_guideChecked || !mounted) return;
    _guideChecked = true;

    final shouldShow = await OnboardingManager.shouldShowHomeGuide();
    if (!shouldShow || !mounted) return;

    await _showHomeGuide(fromOnboarding: true);
  }

  Future<void> _showHomeGuide({bool fromOnboarding = false}) async {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    await SpotlightGuide.show(
      context,
      skipLabel: l10n.guideSkip,
      nextLabel: l10n.guideNext,
      doneLabel: l10n.guideDone,
      onFinished: fromOnboarding ? OnboardingManager.completeHomeGuide : () {},
      steps: [
        SpotlightGuideStep(
          targetKey: _playKey,
          title: l10n.guidePlayTitle,
          description: l10n.guidePlayDesc,
        ),
        SpotlightGuideStep(
          targetKey: _dailyKey,
          title: l10n.guideDailyTitle,
          description: l10n.guideDailyDesc,
        ),
        SpotlightGuideStep(
          targetKey: _calendarKey,
          title: l10n.guideCalendarTitle,
          description: l10n.guideCalendarDesc,
        ),
        SpotlightGuideStep(
          targetKey: _profileKey,
          title: l10n.guideProfileTitle,
          description: l10n.guideProfileDesc,
        ),
        SpotlightGuideStep(
          targetKey: _feedbackKey,
          title: l10n.guideFeedbackTitle,
          description: l10n.guideFeedbackDesc,
        ),
        SpotlightGuideStep(
          targetKey: _settingsKey,
          title: l10n.guideSettingsTitle,
          description: l10n.guideSettingsDesc,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        leadingWidth: 220,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Consumer<ProfileManager>(
              builder: (context, profileManager, child) {
                if (!profileManager.isGuestMode &&
                    profileManager.currentProfile != null) {
                  final avatarColor =
                      profileManager.currentProfile?.avatarColor;
                  return GestureDetector(
                    key: _profileKey,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const UserProfileDisplayPage(),
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
                return SizedBox(key: _profileKey, width: 0, height: 0);
              },
            ),
            IconButton(
              key: _feedbackKey,
              icon: const Icon(Icons.mail_outline, color: Color(0xFF2E7D32)),
              tooltip: l10n.sendFeedback,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FeedbackPage(),
                  ),
                );
              },
            ),
            IconButton(
              icon: Image.asset(
                'assets/images/bamboo.png',
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.eco, color: Color(0xFF2E7D32));
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
            IconButton(
              icon: const Icon(Icons.help_outline, color: Color(0xFF2E7D32)),
              tooltip: l10n.showGuide,
              onPressed: () => _showHomeGuide(),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: _calendarKey,
            icon: const Icon(Icons.calendar_today, color: Color(0xFF2E7D32)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CalendarPage(
                    gameStateManager: widget.gameStateManager,
                  ),
                ),
              );
            },
          ),
          IconButton(
            key: _settingsKey,
            icon: const Icon(Icons.settings, color: Color(0xFF2E7D32)),
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
                        return Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF6F4E37),
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
                Text(
                  l10n.appName,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(flex: 3),
                Consumer<GameStateManager>(
                  builder: (context, manager, child) {
                    if (manager.isLoading) {
                      return const CircularProgressIndicator();
                    }
                    if (manager.hasOngoingGame) {
                      return Column(
                        key: _playKey,
                        children: [
                          _buildButton(
                            context,
                            l10n.continueGame,
                            Icons.play_arrow,
                            const Color(0xFF2E7D32),
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GamePage(
                                    gameStateManager: widget.gameStateManager,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildButton(
                            context,
                            l10n.newGame,
                            Icons.refresh,
                            const Color(0xFF2E7D32),
                            () {
                              _showDifficultyDialog(context);
                            },
                          ),
                        ],
                      );
                    }
                    return KeyedSubtree(
                      key: _playKey,
                      child: _buildButton(
                        context,
                        l10n.play,
                        Icons.play_arrow,
                        const Color(0xFF2E7D32),
                        () {
                          _showDifficultyDialog(context);
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                KeyedSubtree(
                  key: _dailyKey,
                  child: _buildButton(
                    context,
                    l10n.todaysGame,
                    Icons.today,
                    const Color(0xFF6F4E37),
                    () async {
                      final dailyGameManager = DailyGameManager();
                      final today = DateTime.now();
                      final game = await dailyGameManager.getDailyGame(today);
                      widget.gameStateManager.startNewGame(game);
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GamePage(
                              gameStateManager: widget.gameStateManager,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildButton(
                  context,
                  l10n.logout,
                  Icons.logout,
                  Colors.red.shade300,
                  () async {
                    final profileManager =
                        Provider.of<ProfileManager>(context, listen: false);
                    await profileManager.logout();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.loggedOutSuccess),
                        ),
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
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.selectDifficulty),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDifficultyOption(
                dialogContext,
                l10n.easy,
                const Color(0xFF2E7D32),
                () => _startNewGame(context, dialogContext, 'Easy'),
              ),
              const SizedBox(height: 12),
              _buildDifficultyOption(
                dialogContext,
                l10n.medium,
                Colors.orange,
                () => _startNewGame(context, dialogContext, 'Medium'),
              ),
              const SizedBox(height: 12),
              _buildDifficultyOption(
                dialogContext,
                l10n.hard,
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
    Navigator.pop(dialogContext);

    SudokuGame newGame = SudokuGenerator.generateNewGame(difficulty: difficulty);
    widget.gameStateManager.startNewGame(newGame);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GamePage(
          gameStateManager: widget.gameStateManager,
        ),
      ),
    );
  }
}
