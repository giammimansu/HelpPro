import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'debug/debug_config.dart';
import 'utils/memory_manager.dart';

void main() async {
  // Inizializzazione robusta
  WidgetsFlutterBinding.ensureInitialized();

  // Gestione errori globali
  FlutterError.onError = (FlutterErrorDetails details) {
    DebugConfig.logError('Flutter Error', details.exception, details.stack);
  };

  // Inizializza il Memory Manager
  MemoryManager.initialize();
  DebugConfig.log('Memory Manager inizializzato');

  // Setup asincrono ottimizzato
  await setup();

  runApp(const MyApp());
}

Future<void> setup() async {
  DebugConfig.log('Inizio setup applicazione');

  try {
    // Caricamento .env con timeout per evitare blocchi
    await dotenv
        .load(fileName: ".env")
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            DebugConfig.log(
              'Timeout caricamento .env, usando configurazione di default',
            );
            throw Exception('Timeout .env loading');
          },
        );

    final token = dotenv.env['MAPBOX_ACCESS_TOKEN'];
    if (token != null && token.isNotEmpty) {
      MapboxOptions.setAccessToken(token);
      DebugConfig.log('Mapbox token configurato');
    } else {
      DebugConfig.logError('Token Mapbox non trovato nel file .env');
      throw Exception('MAPBOX_ACCESS_TOKEN not found in .env file');
    }
  } catch (e) {
    // Configurazione di fallback per evitare crash
    print('⚠️ Warning: .env file not found or invalid token: $e');
    print('🔄 App continuerà senza Mapbox (modalità limitata)');
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
