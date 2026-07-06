import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_state_manager.dart';
import '../services/profile_manager.dart';
import 'home_page.dart';
import 'login_page.dart';

/// Giriş yapılmadan uygulamanın geri kalanına izin vermez.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileManager>().ensureInitialized();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileManager>(
      builder: (context, profileManager, child) {
        if (!profileManager.isInitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (profileManager.isGuestMode || profileManager.currentProfile == null) {
          return const LoginPage();
        }

        final gameStateManager = context.watch<GameStateManager>();
        return HomePage(gameStateManager: gameStateManager);
      },
    );
  }
}
