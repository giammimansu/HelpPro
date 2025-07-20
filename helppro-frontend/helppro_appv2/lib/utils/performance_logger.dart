// lib/utils/performance_logger.dart
import 'performance_config.dart';

class PerformanceLogger {
  static final Map<String, DateTime> _startTimes = {};

  static void startTimer(String operation) {
    if (PerformanceConfig.enablePerformanceLogs) {
      _startTimes[operation] = DateTime.now();
      debugLog('⏱️ Inizio: $operation');
    }
  }

  static void endTimer(String operation) {
    if (PerformanceConfig.enablePerformanceLogs &&
        _startTimes.containsKey(operation)) {
      final startTime = _startTimes[operation]!;
      final duration = DateTime.now().difference(startTime);
      debugLog('✅ Fine: $operation - Durata: ${duration.inMilliseconds}ms');
      _startTimes.remove(operation);
    }
  }

  static void logMemoryUsage(String context) {
    if (PerformanceConfig.enablePerformanceLogs) {
      debugLog('💾 Memory check: $context');
      // Qui potresti aggiungere logiche più avanzate per il monitoraggio della memoria
    }
  }

  static void debugLog(String message) {
    if (PerformanceConfig.enableDebugLogs) {
      print('[PERF] $message');
    }
  }

  static void errorLog(String message, [dynamic error]) {
    print('[ERROR] $message');
    if (error != null) {
      print('[ERROR] Details: $error');
    }
  }

  static void networkLog(String url, int statusCode, Duration duration) {
    if (PerformanceConfig.enablePerformanceLogs) {
      debugLog(
        '🌐 Network: $url - Status: $statusCode - Time: ${duration.inMilliseconds}ms',
      );
    }
  }
}
