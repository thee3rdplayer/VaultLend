import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages PIN‑based authentication and automatic idle timeout.
class AuthService extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  static const _pinHashKey = 'pin_hash';
  static const idleTimeout = Duration(minutes: 2); // 2‑minute auto‑lock

  bool _locked = true;
  Timer? _idleTimer;
  String? _storedHash;

  /// True if the app is currently locked (PIN must be entered).
  bool get isLocked => _locked;

  /// True if no PIN has ever been saved – first‑run setup.
  bool get needsPinSetup => _storedHash == null && !_locked;

  AuthService() {
    _init();
  }

  /// Load the stored PIN hash and decide the initial state:
  /// - No PIN → start unlocked but mark that setup is needed.
  /// - PIN exists → start locked.
  Future<void> _init() async {
    _storedHash = await _storage.read(key: _pinHashKey);
    if (_storedHash == null) {
      // First launch: no PIN yet, start unlocked so the user can set it
      _locked = false;
    } else {
      _locked = true;
    }
    notifyListeners();
  }

  /// Try to unlock with the given PIN.
  Future<bool> login(String pin) async {
    final hash = sha256.convert(utf8.encode(pin)).toString();
    if (hash == _storedHash) {
      _locked = false;
      _startTimer();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Check a PIN without changing state (used for password change).
  Future<bool> verifyPin(String pin) async {
    final hash = sha256.convert(utf8.encode(pin)).toString();
    return hash == _storedHash;
  }

  /// Store a new PIN hash.
  Future<void> setPin(String pin) async {
    final hash = sha256.convert(utf8.encode(pin)).toString();
    await _storage.write(key: _pinHashKey, value: hash);
    _storedHash = hash;
  }

  /// Force lock the app.
  void logout() {
    _locked = true;
    _idleTimer?.cancel();
    notifyListeners();
  }

  /// Reset the idle timer. Call this on every user interaction.
  void onUserInteraction() {
    if (!_locked) {
      _idleTimer?.cancel();
      _startTimer();
    }
  }

  void _startTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(idleTimeout, logout);
  }
}