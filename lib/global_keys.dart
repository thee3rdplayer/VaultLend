import 'package:flutter/material.dart';

/// A global ScaffoldMessenger key attached to the root MaterialApp.
/// Use this to show snackbars from anywhere, even when the current
/// widget's context is unstable (e.g., after auto‑lock).
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();