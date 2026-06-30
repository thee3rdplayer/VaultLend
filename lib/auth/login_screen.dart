import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import '../theme.dart';

/// PIN entry screen for LuchiKwacha.
/// Displays error messages directly on the screen (no snackbar needed).
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
  String? _errorMessage;   // displayed below the PIN fields

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
    if (pin.length < 4) {
      setState(() => _errorMessage = 'PIN must be at least 4 digits');
      return;
    }

    final auth = context.read<AuthService>();

    if (_isFirstRun) {
      if (pin != confirm) {
        HapticFeedback.heavyImpact();
        _pinCtrl.clear();
        _confirmCtrl.clear();
        setState(() => _errorMessage = 'PINs do not match – please try again');
        return;
      }
      setState(() => _errorMessage = null);
      await auth.setPin(pin);
      await auth.login(pin);
    } else {
      final success = await auth.login(pin);
      if (!mounted) return;
      if (success) {
        _attempts = 0;
        setState(() => _errorMessage = null);
      } else {
        HapticFeedback.heavyImpact();
        _pinCtrl.clear();
        _attempts++;
        if (_attempts >= 5) {
          _startLockout();
          setState(() => _errorMessage = 'Too many attempts. Wait 30 seconds.');
        } else {
          setState(() => _errorMessage = 'Incorrect PIN (${5 - _attempts} tries left)');
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
      if (mounted) {
        setState(() {
          _lockedOut = false;
          _errorMessage = null;
        });
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
              Text('LUCHI-KWACHA',
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
                autofocus: true,
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
              const SizedBox(height: 12),
              // In‑line error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _errorMessage!,
                    style: VaultFonts.body(13, color: VaultColors.neonPink),
                    textAlign: TextAlign.center,
                  ),
                ),
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