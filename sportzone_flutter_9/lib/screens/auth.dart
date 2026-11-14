import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../models/user_models.dart';
import '../services/auth_service.dart';
import 'home_shell.dart';
import 'login.dart';
import 'onboarding_screen.dart';

/// Decide qué pantalla mostrar: login o la app.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF10131A),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFB7F34A)),
            ),
          );
        }

        if (snapshot.hasData) {
          return ListenableBuilder(
            listenable: appState,
            builder: (context, _) => appState.onboardingDone
                ? const HomeShell()
                : const OnboardingScreen(),
          );
        }

        return const LoginScreen();
      },
    );
  }
}
