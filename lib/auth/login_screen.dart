import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import '../theme.dart';

/// PIN entry screen. If no PIN exists, we create one; otherwise we unlock.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _pinCtrl = TextEditingController();
  bool _isFirstRun = false; // true when there is no stored PIN yet

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    _isFirstRun = auth.needsPinSetup;
  }

  /// Validate and process the entered PIN.
  Future<void> _submit() async {
    final pin = _pinCtrl.text.trim();
    if (pin.length < 4) return;

    final auth = context.read<AuthService>();
    if (_isFirstRun) {
      await auth.setPin(pin);
      await auth.login(pin); // auto‑unlock after setting
    } else {
      final success = await auth.login(pin);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Incorrect PIN', style: VaultFonts.body(13)),
          ),
        );
      }
    }
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
                onPressed: _submit,
                child: Text(_isFirstRun ? 'SET PIN' : 'LOGIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}