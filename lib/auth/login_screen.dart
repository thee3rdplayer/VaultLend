import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import '../theme.dart';

/// PIN entry screen with lockout UI.
/// Displays a countdown timer when the account is temporarily locked.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _pinCtrl = TextEditingController();
  bool _isFirstRun = false;
  Timer? _lockoutTimer;   // periodic timer to refresh the remaining time

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    _isFirstRun = !auth.hasPin;

    // If we are already in lockout, start a periodic timer to update the UI
    _syncLockoutTimer(auth);
  }

  /// Restart the lockout timer when auth state changes.
  void _syncLockoutTimer(AuthService auth) {
    _lockoutTimer?.cancel();
    if (auth.isLockedOut) {
      _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
        if (!auth.isLockedOut) {
          _lockoutTimer?.cancel();
          if (mounted) setState(() {});
        }
      });
    }
  }

  Future<void> _submit() async {
    final pin = _pinCtrl.text.trim();
    if (pin.length < 4) return;

    final auth = context.read<AuthService>();
    if (_isFirstRun) {
      await auth.setPin(pin);
      await auth.login(pin); // auto‑login after setting
    } else {
      final ok = await auth.login(pin);
      if (!ok && mounted) {
        if (auth.isLockedOut) {
          _syncLockoutTimer(auth);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Incorrect PIN. ${AuthService.maxAttempts - auth.failedAttempts} attempts remaining.',
                style: VaultFonts.body(13),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final lockedOut = auth.isLockedOut;
    final remaining = auth.remainingLockout;

    return Scaffold(
      backgroundColor: VaultColors.voidBlack,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('VAULT-LEND',
                  style: VaultFonts.exo(28, weight: FontWeight.w700)),
              const SizedBox(height: 24),
              if (lockedOut) ...[
                // Lockout message and countdown
                const Icon(Icons.lock_outline,
                    size: 48, color: VaultColors.neonPink),
                const SizedBox(height: 16),
                Text(
                  'Too many attempts',
                  style: VaultFonts.exo(16, weight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try again in ${_formatDuration(remaining!)}',
                  style: VaultFonts.raj(18, color: VaultColors.neonPurple),
                ),
              ] else ...[
                Text(
                  _isFirstRun ? 'Create a 4‑digit PIN' : 'Enter PIN',
                  style: VaultFonts.body(15),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pinCtrl,
                  obscureText: true,
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: VaultFonts.raj(24, color: VaultColors.neonPurple),
                  enabled: !lockedOut,
                  decoration: const InputDecoration(
                    counterText: '',
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0x55C44DFF)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: VaultColors.neonPurple),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: lockedOut ? null : _submit,
                  child: Text(_isFirstRun ? 'SET PIN' : 'LOGIN'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds.remainder(60);
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}