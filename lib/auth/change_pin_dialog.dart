import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import '../theme.dart';

/// Dialog that lets the user change their app PIN.
/// Fields are cleared on incorrect old PIN or mismatch.
/// Keyboard opens automatically.
class ChangePinDialog extends StatefulWidget {
  const ChangePinDialog({super.key});

  @override
  State<ChangePinDialog> createState() => _ChangePinDialogState();
}

class _ChangePinDialogState extends State<ChangePinDialog> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  Future<void> _change() async {
    final oldPin = _oldCtrl.text.trim();
    final newPin = _newCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();
    final auth = context.read<AuthService>();

    if (oldPin.isEmpty || newPin.isEmpty || confirm.isEmpty) {
      _showMsg('All fields are required');
      return;
    }
    if (newPin.length < 4) {
      _showMsg('New PIN must be at least 4 digits');
      return;
    }
    if (newPin != confirm) {
      HapticFeedback.heavyImpact();
      _newCtrl.clear();
      _confirmCtrl.clear();
      _showMsg('New PINs do not match');
      return;
    }
    final ok = await auth.verifyPin(oldPin);
    if (!ok) {
      HapticFeedback.heavyImpact();
      _oldCtrl.clear();
      _newCtrl.clear();
      _confirmCtrl.clear();
      _showMsg('Old PIN is incorrect');
      return;
    }
    await auth.setPin(newPin);
    if (mounted) Navigator.of(context).pop(true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PIN updated successfully',
              style: VaultFonts.body(13)),
        ),
      );
    }
  }

  void _showMsg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text, style: VaultFonts.body(13))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: VaultColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: VaultColors.neonPurple.withValues(alpha: 0.5)),
      ),
      title: Text('CHANGE PIN',
          style: VaultFonts.exo(16, weight: FontWeight.w700)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _oldCtrl,
              obscureText: true,
              maxLength: 4,
              keyboardType: TextInputType.number,
              autofocus: true,   // open keyboard automatically
              decoration: const InputDecoration(
                  labelText: 'Old PIN', counterText: ''),
              style: VaultFonts.raj(16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newCtrl,
              obscureText: true,
              maxLength: 4,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'New PIN', counterText: ''),
              style: VaultFonts.raj(16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmCtrl,
              obscureText: true,
              maxLength: 4,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Confirm New PIN', counterText: ''),
              style: VaultFonts.raj(16),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel',
              style: VaultFonts.body(13, color: VaultColors.textDim)),
        ),
        ElevatedButton(
          onPressed: _change,
          child: const Text('Change'),
        ),
      ],
    );
  }
}