import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/game_state_manager.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const SudokuApp());
}

class SudokuApp extends StatelessWidget {
  const SudokuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameStateManager(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Sudoku Master',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const HomePageWrapper(),
      ),
    );
  }
}

class HomePageWrapper extends StatelessWidget {
  const HomePageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final gameStateManager = Provider.of<GameStateManager>(context);
    return HomePage(gameStateManager: gameStateManager);
  }
}
