import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

void main() async {
  await setup();
  runApp(const MyApp());
}

Future<void> setup() async {
  await dotenv.load(fileName: ".env");
  final token = dotenv.env['MAPBOX_ACCESS_TOKEN'];
  if (token != null && token.isNotEmpty) {
    MapboxOptions.setAccessToken(token);
  } else {
    throw Exception('MAPBOX_ACCESS_TOKEN not found in .env file');
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
