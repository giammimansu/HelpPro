// lib/utils/debouncer.dart
import 'dart:async';

class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  void call(VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(delay, callback);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

class Throttler {
  final Duration duration;
  DateTime? _lastExecution;

  Throttler({required this.duration});

  bool call(VoidCallback callback) {
    final now = DateTime.now();
    if (_lastExecution == null || now.difference(_lastExecution!) >= duration) {
      _lastExecution = now;
      callback();
      return true;
    }
    return false;
  }
}

typedef VoidCallback = void Function();
