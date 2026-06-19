import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import '../theme.dart';

/// PIN entry screen.
/// - If no PIN exists, it lets the user create one.
/// - If a PIN exists, it acts as a login screen.
/// - After 5 consecutive wrong attempts, a 30‑second lockout is enforced.
/// - The password field clears automatically on a wrong attempt.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _pinCtrl = TextEditingController();
  bool _isFirstRun = false; // true when no PIN has been set yet
  int _attempts = 0;        // failed attempts counter
  bool _lockedOut = false;  // true during temporary lockout
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    _isFirstRun = auth.needsPinSetup;
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  /// Validate and process the entered PIN.
  Future<void> _submit() async {
    if (_lockedOut) return;

    final pin = _pinCtrl.text.trim();
    if (pin.length < 4) return;

    final auth = context.read<AuthService>();
    if (_isFirstRun) {
      // First launch – store the new PIN and auto‑login
      await auth.setPin(pin);
      await auth.login(pin);
    } else {
      final success = await auth.login(pin);
      if (success) {
        _attempts = 0; // reset on correct PIN
      } else {
        _pinCtrl.clear();  // auto‑clear so user can retype immediately
        _attempts++;
        if (_attempts >= 5) {
          _startLockout();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _attempts >= 5
                    ? 'Too many attempts. Wait 30 seconds.'
                    : 'Incorrect PIN (${5 - _attempts} tries left)',
                style: VaultFonts.body(13),
              ),
            ),
          );
        }
      }
    }
  }

  void _startLockout() {
    _lockedOut = true;
    _pinCtrl.clear();
    // After 30 seconds, allow attempts again (keep the attempt counter)
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) {
        setState(() => _lockedOut = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                enabled: !_lockedOut,
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
                onPressed: _lockedOut ? null : _submit,
                child: Text(
                  _lockedOut
                      ? 'Locked (30s)'
                      : (_isFirstRun ? 'SET PIN' : 'LOGIN'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}