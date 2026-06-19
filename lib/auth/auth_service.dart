import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages PIN authentication with lockout after 3 consecutive failures.
/// On lockout, the app disables PIN entry for 1 minute.
class AuthService extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  static const _pinHashKey = 'pin_hash';
  static const _failedAttemptsKey = 'failed_attempts';
  static const _lockoutUntilKey = 'lockout_until';

  static const idleTimeout = Duration(minutes: 2);   // auto‑lock after idle
  static const maxAttempts = 3;
  static const lockoutDuration = Duration(minutes: 1);

  bool _locked = true;
  Timer? _idleTimer;
  String? _storedHash;

  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  bool get isLocked => _locked;
  bool get hasPin => _storedHash != null;

  /// True if the user is currently locked out due to too many failures.
  bool get isLockedOut => _lockoutUntil != null && _lockoutUntil!.isAfter(DateTime.now());
  
  /// Remaining lockout time as a Duration, or null if not locked out.
  Duration? get remainingLockout {
    if (_lockoutUntil == null) return null;
    final remaining = _lockoutUntil!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  /// Number of consecutive failed attempts since last success.
  int get failedAttempts => _failedAttempts;

  AuthService() {
    _init();
  }

  Future<void> _init() async {
    _storedHash = await _storage.read(key: _pinHashKey);
    _locked = _storedHash != null;

    // Restore failed attempts and lockout state from secure storage
    final attempts = await _storage.read(key: _failedAttemptsKey);
    _failedAttempts = int.tryParse(attempts ?? '') ?? 0;

    final lockoutStr = await _storage.read(key: _lockoutUntilKey);
    if (lockoutStr != null) {
      _lockoutUntil = DateTime.tryParse(lockoutStr);
      // If lockout has expired, clear it
      if (_lockoutUntil != null && !_lockoutUntil!.isAfter(DateTime.now())) {
        _lockoutUntil = null;
        await _clearLockoutState();
      }
    }

    if (_locked) _startIdleTimer();
    notifyListeners();
  }

  /// Attempt to unlock. Returns true on success.
  /// On failure, increments failed count and may trigger lockout.
  Future<bool> login(String pin) async {
    // If already locked out, reject immediately
    if (isLockedOut) return false;

    final hash = sha256.convert(utf8.encode(pin)).toString();
    if (hash == _storedHash) {
      _resetFailedAttempts();
      _locked = false;
      _startIdleTimer();
      notifyListeners();
      return true;
    }

    // Wrong PIN
    _failedAttempts++;
    await _storage.write(key: _failedAttemptsKey, value: _failedAttempts.toString());

    if (_failedAttempts >= maxAttempts) {
      // Trigger lockout
      _lockoutUntil = DateTime.now().add(lockoutDuration);
      await _storage.write(key: _lockoutUntilKey, value: _lockoutUntil!.toIso8601String());
      notifyListeners();
    }
    return false;
  }

  /// Check a PIN without changing state (for password change).
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

  /// Manual lock (e.g. user presses logout).
  void logout() {
    _locked = true;
    _idleTimer?.cancel();
    notifyListeners();
  }

  /// Reset idle timer on any interaction.
  void onUserInteraction() {
    if (!_locked) {
      _idleTimer?.cancel();
      _startIdleTimer();
    }
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(idleTimeout, logout);
  }

  /// Reset failed attempts and clear lockout.
  void _resetFailedAttempts() async {
    _failedAttempts = 0;
    _lockoutUntil = null;
    await _clearLockoutState();
  }

  Future<void> _clearLockoutState() async {
    await _storage.delete(key: _failedAttemptsKey);
    await _storage.delete(key: _lockoutUntilKey);
  }
}