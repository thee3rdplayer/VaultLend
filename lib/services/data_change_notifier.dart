import 'package:flutter/material.dart';

/// A simple observable that any part of the app can call when data changes.
/// All tabs listen to this and refresh automatically.
class DataChangeNotifier extends ChangeNotifier {
  void notifyDataChanged() => notifyListeners();
}