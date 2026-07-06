import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../l10n/app_localizations.dart';
import '../services/daily_game_manager.dart';
import '../services/game_state_manager.dart';
import '../models/sudoku_game.dart';
import 'game_page.dart';

class CalendarPage extends StatefulWidget {
  final GameStateManager gameStateManager;

  const CalendarPage({super.key, required this.gameStateManager});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  final DailyGameManager _dailyGameManager = DailyGameManager();
  Map<String, SudokuGame> _dailyGames = {};
  
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _loadDailyGames();
  }

  Future<void> _loadDailyGames() async {
    final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    
    Map<String, SudokuGame> games = {};
    for (var day = firstDay; day.isBefore(lastDay.add(const Duration(days: 1))); day = day.add(const Duration(days: 1))) {
      final dateKey = _getDateKey(day);
      try {
        if (await _dailyGameManager.hasDailyGame(day)) {
          games[dateKey] = await _dailyGameManager.getDailyGame(day);
        }
      } catch (e) {
        // Hata durumunda devam et
      }
    }
    
    setState(() {
      _dailyGames = games;
    });
  }

  Future<void> _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    
    // Seçilen günün oyununu yükle
    final dateKey = _getDateKey(selectedDay);
    if (!_dailyGames.containsKey(dateKey)) {
      try {
        final game = await _dailyGameManager.getDailyGame(selectedDay);
        setState(() {
          _dailyGames[dateKey] = game;
        });
      } catch (e) {
        // Hata durumunda devam et
      }
    }
  }

  Future<void> _onPageChanged(DateTime focusedDay) async {
    setState(() {
      _focusedDay = focusedDay;
    });
    await _loadDailyGames();
  }

  Future<void> _playDailyGame(DateTime date) async {
    // Gelecek tarihler için oyun oynatma
    if (_isFutureDate(date)) {
      return;
    }
    
    final dateKey = DateTime(date.year, date.month, date.day);
    final game = await _dailyGameManager.getDailyGame(dateKey);
    
    // Oyunu gameStateManager'a yükle
    widget.gameStateManager.startNewGame(game);
    
    // Oyun sayfasına git
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GamePage(
            gameStateManager: widget.gameStateManager,
          ),
        ),
      ).then((_) {
        // Oyun sayfasından dönünce günlük oyunları yeniden yükle
        _loadDailyGames();
      });
    }
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isFutureDate(DateTime date) {
    final today = DateTime.now();
    final selected = DateTime(date.year, date.month, date.day);
    final todayDate = DateTime(today.year, today.month, today.day);
    return selected.isAfter(todayDate);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateKey = _getDateKey(_selectedDay);
    final selectedGame = _dailyGames[dateKey];
    final isToday = _isSameDay(_selectedDay, DateTime.now());
    final isCompleted = selectedGame?.isCompleted ?? false;
    final isFuture = _isFutureDate(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dailyCalendarTitle),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Column(
        children: [
          TableCalendar<SudokuGame>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => _isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            onPageChanged: _onPageChanged,
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              todayDecoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Color(0xFF6F4E37),
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            eventLoader: (day) {
              final key = _getDateKey(day);
              final game = _dailyGames[key];
              if (game != null && game.isCompleted) {
                return [game];
              }
              return [];
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return const Positioned(
                    bottom: 0,
                    child: Icon(
                      Icons.star,
                      size: 16,
                      color: Color(0xFFFFB300),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const Divider(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6F4E37),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isFuture)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            l10n.futureDateUnavailable,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isCompleted)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF2E7D32)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 8),
                          Text(
                            l10n.completed,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () => _playDailyGame(_selectedDay),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isToday 
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF6F4E37),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_arrow, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              isToday ? l10n.playTodaysGame : l10n.playDaysGame,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (selectedGame != null && !isCompleted) ...[
                    const SizedBox(height: 16),
                    Text(
                      l10n.difficultyLabel(selectedGame.difficulty),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6F4E37),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

