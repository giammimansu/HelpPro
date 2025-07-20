// lib/debug/debug_config.dart
class DebugConfig {
  static const bool isDebugMode = true;
  static const bool enableNetworkLogs = true;
  static const bool enablePerformanceLogs = true;
  static const bool enableLocationLogs = true;

  // Service Protocol settings
  static const bool disableServiceAuthCodes = true;
  static const Duration connectionTimeout = Duration(seconds: 30);

  // Hot reload settings
  static const bool enableHotReload = true;
  static const bool preserveState = true;

  static void log(String message) {
    if (isDebugMode) {
      print('[DEBUG] ${DateTime.now().toIso8601String()}: $message');
    }
  }

  static void logError(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    print('[ERROR] ${DateTime.now().toIso8601String()}: $message');
    if (error != null) {
      print('[ERROR] Details: $error');
    }
    if (stackTrace != null) {
      print('[ERROR] Stack: $stackTrace');
    }
  }

  static void logNetwork(
    String method,
    String url,
    int? statusCode, [
    Duration? duration,
  ]) {
    if (enableNetworkLogs) {
      final durationStr = duration != null
          ? ' (${duration.inMilliseconds}ms)'
          : '';
      log('NETWORK: $method $url -> $statusCode$durationStr');
    }
  }

  static void logLocation(String event, [Map<String, dynamic>? details]) {
    if (enableLocationLogs) {
      final detailsStr = details != null ? ' - $details' : '';
      log('LOCATION: $event$detailsStr');
    }
  }
}
