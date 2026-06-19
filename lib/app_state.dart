import 'package:flutter/foundation.dart';

/// Simple notifier that increments a counter every time [refresh] is called.
/// Tabs depend on this counter to auto‑rebuild after data changes.
class AppState extends ChangeNotifier {
  int _counter = 0;

  int get counter => _counter;

  void refresh() {
    _counter++;
    notifyListeners();
  }
}