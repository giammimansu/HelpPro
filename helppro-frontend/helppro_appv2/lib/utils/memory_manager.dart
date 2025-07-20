// lib/utils/memory_manager.dart
import 'dart:async';

class MemoryManager {
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static Timer? _cleanupTimer;

  // Configurazioni per gestione memoria
  static const int maxCacheSize = 50; // Ridotto da 100
  static const Duration cacheLifetime = Duration(minutes: 3); // Ridotto da 5
  static const Duration cleanupInterval = Duration(minutes: 1);

  static void initialize() {
    // Avvia pulizia periodica
    _cleanupTimer = Timer.periodic(cleanupInterval, (timer) {
      _cleanupExpiredEntries();
    });
  }

  static void dispose() {
    _cleanupTimer?.cancel();
    clearAll();
  }

  static void put(String key, dynamic value) {
    // Verifica dimensioni cache prima di aggiungere
    if (_cache.length >= maxCacheSize) {
      _removeOldestEntry();
    }

    _cache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
  }

  static T? get<T>(String key) {
    if (!_cache.containsKey(key)) {
      return null;
    }

    // Verifica se è scaduto
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null ||
        DateTime.now().difference(timestamp) > cacheLifetime) {
      remove(key);
      return null;
    }

    return _cache[key] as T?;
  }

  static void remove(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
  }

  static void clearAll() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  static void _removeOldestEntry() {
    if (_cacheTimestamps.isEmpty) return;

    final oldestEntry = _cacheTimestamps.entries.reduce(
      (a, b) => a.value.isBefore(b.value) ? a : b,
    );

    remove(oldestEntry.key);
  }

  static void _cleanupExpiredEntries() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) > cacheLifetime) {
        expiredKeys.add(key);
      }
    });

    for (final key in expiredKeys) {
      remove(key);
    }

    print('🧹 Memory cleanup: rimossi ${expiredKeys.length} elementi scaduti');
  }

  static Map<String, dynamic> getMemoryStats() {
    return {
      'cacheSize': _cache.length,
      'maxSize': maxCacheSize,
      'usage': '${((_cache.length / maxCacheSize) * 100).toStringAsFixed(1)}%',
    };
  }
}
