import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
// qui alias per evitare collisione
import 'screens/map_screen.dart' as map_screen;

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
      home: Consumer<AuthService>(
        builder: (context, auth, _) {
          return auth.isLoggedIn ? const HomeScreen() : const LoginScreen();
        },
      ),
      routes: {
        '/signup': (_) => const SignupScreen(),
        // se vuoi una rotta per la mappa:
        '/map': (_) => const map_screen.MapScreen(),
      },
    );
  }
}
