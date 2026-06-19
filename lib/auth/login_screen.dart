import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';   // for HapticFeedback
import 'package:provider/provider.dart';
import 'auth_service.dart';
import '../theme.dart';

/// PIN entry screen.
/// - First run: two fields (PIN + confirm), creates the PIN.
/// - Subsequent launches: single field, login.
/// - Haptic feedback on wrong entry.
/// - 5 wrong attempts → 30‑second lockout.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isFirstRun = false;
  int _attempts = 0;
  bool _lockedOut = false;
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
    _confirmCtrl.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_lockedOut) return;

    final pin = _pinCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();
    if (pin.length < 4) return;

    final auth = context.read<AuthService>();

    if (_isFirstRun) {
      // First‑run: check confirmation matches
      if (pin != confirm) {
        _showError('PINs do not match');
        return;
      }
      await auth.setPin(pin);
      await auth.login(pin);
      // Success – dashboard will appear
    } else {
      final success = await auth.login(pin);
      if (success) {
        _attempts = 0;
      } else {
        HapticFeedback.heavyImpact();   // vibrate on wrong PIN
        _pinCtrl.clear();
        _attempts++;
        if (_attempts >= 5) {
          _startLockout();
          _showError('Too many attempts. Wait 30 seconds.');
        } else {
          _showError('Incorrect PIN (${5 - _attempts} tries left)');
        }
      }
    }
  }

  void _startLockout() {
    _lockedOut = true;
    _pinCtrl.clear();
    _confirmCtrl.clear();
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) setState(() => _lockedOut = false);
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: VaultFonts.body(13))),
    );
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
                _isFirstRun
                    ? 'Welcome!\nCreate a secure PIN to protect your data.'
                    : 'Enter your PIN',
                textAlign: TextAlign.center,
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
                decoration: InputDecoration(
                  counterText: '',
                  hintText: _isFirstRun ? 'Choose PIN' : null,
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0x55C44DFF)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: VaultColors.neonPurple),
                  ),
                ),
              ),
              // Confirm field only on first run
              if (_isFirstRun) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmCtrl,
                  obscureText: true,
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: VaultFonts.raj(24, color: VaultColors.neonPurple),
                  enabled: !_lockedOut,
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: 'Confirm PIN',
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0x55C44DFF)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: VaultColors.neonPurple),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _lockedOut ? null : _submit,
                child: Text(
                  _lockedOut
                      ? 'Locked (30s)'
                      : (_isFirstRun ? 'CREATE PIN' : 'UNLOCK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}