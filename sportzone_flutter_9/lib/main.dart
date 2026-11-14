
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/app_state.dart';
import 'core/app_theme.dart';
import 'screens/auth.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SportZoneApp());
}

class SportZoneApp extends StatelessWidget {
  const SportZoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'SportZone',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: appState.themeMode,
          themeAnimationDuration: const Duration(milliseconds: 450),
          themeAnimationCurve: Curves.easeInOut,
          home: const AuthGate(),
        );
      },
    );
  }
}
