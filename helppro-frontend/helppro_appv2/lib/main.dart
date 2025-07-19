import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setup();
  runApp(const MyApp());
}

Future<void> setup() async {
  try {
    await dotenv.load(fileName: ".env");
    final token = dotenv.env['MAPBOX_ACCESS_TOKEN'];
    if (token != null && token.isNotEmpty) {
      MapboxOptions.setAccessToken(token);
    } else {
      throw Exception('MAPBOX_ACCESS_TOKEN not found in .env file');
    }
  } catch (e) {
    // Se il file .env non esiste, usa un token di default o mostra errore
    print('Warning: .env file not found or invalid token: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'HelpPro', home: HomePage());
  }
}
