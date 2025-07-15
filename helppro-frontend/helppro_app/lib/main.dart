// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthService()..loadToken(),
      child: const HelpProApp(),
    ),
  );
}

class HelpProApp extends StatelessWidget {
  const HelpProApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HelpPro',
      theme: ThemeData(primarySwatch: Colors.blue),
      // All’avvio, scelgo la schermata in base allo stato di login
      home: Consumer<AuthService>(
        builder: (ctx, auth, _) {
          if (auth.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return auth.isLoggedIn ? const HomeScreen() : const LoginScreen();
        },
      ),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/home': (_) => const HomeScreen(),
        // Attenzione: qui uso le () per invocare il costruttore
        '/map': (_) => const MapScreen(),
      },
    );
  }
}
