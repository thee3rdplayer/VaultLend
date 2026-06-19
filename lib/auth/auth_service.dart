import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages PIN‑based authentication and automatic idle timeout.
class AuthService extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  static const _pinHashKey = 'pin_hash';
  static const idleTimeout = Duration(minutes: 2); // auto‑lock after 2 min idle

  bool _locked = true;
  Timer? _idleTimer;
  String? _storedHash; // null if no PIN has ever been set

  /// True if the app is currently locked.
  bool get isLocked => _locked;

  /// True if no PIN has been saved (first‑run setup).
  /// We treat an empty string the same as null for robustness.
  bool get needsPinSetup => _storedHash == null && !_locked;

  /// True if a PIN has been successfully stored (non‑empty hash).
  bool get hasPin => _storedHash != null && _storedHash!.isNotEmpty;

  AuthService() {
    _init();
  }

  /// Load the stored PIN hash.
  /// If the key is missing or the stored value is an empty string,
  /// we consider no PIN set and start unlocked so the user can set one.
  Future<void> _init() async {
    _storedHash = await _storage.read(key: _pinHashKey);
    if (_storedHash != null && _storedHash!.isEmpty) {
      _storedHash = null; // treat empty as "no PIN" (fixes platform quirk)
    }
    if (_storedHash == null) {
      // No PIN yet → start unlocked; user will be prompted to create one
      _locked = false;
    } else {
      _locked = true;
    }
    notifyListeners();
  }

  /// Attempt to unlock with the given PIN.
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

  /// Verify a PIN without changing lock state (used for password change).
  Future<bool> verifyPin(String pin) async {
    final hash = sha256.convert(utf8.encode(pin)).toString();
    return hash == _storedHash;
  }

  /// Store a new PIN hash. Never stores an empty string.
  Future<void> setPin(String pin) async {
    if (pin.isEmpty) return;
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