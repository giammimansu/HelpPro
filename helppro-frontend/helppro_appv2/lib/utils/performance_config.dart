// lib/utils/performance_config.dart
class PerformanceConfig {
  // Configurazioni per la geolocalizzazione
  static const Duration locationTimeout = Duration(seconds: 5);
  static const Duration lastKnownLocationTimeout = Duration(seconds: 2);

  // Configurazioni per le richieste di rete
  static const Duration networkTimeout = Duration(seconds: 10);
  static const Duration cacheValidityDuration = Duration(minutes: 5);

  // Configurazioni per la ricerca
  static const Duration searchDebounceTime = Duration(milliseconds: 300);

  // Configurazioni per la mappa
  static const Duration mapInitDelay = Duration(milliseconds: 100);
  static const double defaultZoom = 12.5;
  static const double maxZoom = 18.0;
  static const double minZoom = 8.0;

  // Configurazioni per i marker
  static const double minMarkerScale = 0.1;
  static const double maxMarkerScale = 0.4;
  static const int maxMarkersOnScreen = 100;

  // Posizione di default (Roma)
  static const double defaultLatitude = 41.9028;
  static const double defaultLongitude = 12.4964;

  // Configurazioni per l'app
  static const Duration splashScreenMinDuration = Duration(milliseconds: 1000);
  static const int maxCacheSize = 10;

  // Logging
  static const bool enableDebugLogs = true;
  static const bool enablePerformanceLogs = true;
}
