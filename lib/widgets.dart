import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/transaction.dart';
import 'services/database_service.dart';
import 'theme.dart';

/// A styled tile for displaying a loan transaction.
/// Shows name, amount, due date, remaining days, and overdue highlight.
class TransactionTile extends StatelessWidget {
  final LoanTransaction tx;
  final VoidCallback? onAudit; // called on long‑press to open audit

  const TransactionTile({super.key, required this.tx, this.onAudit});

  @override
  Widget build(BuildContext context) {
    final days = tx.daysUntilDue;
    final isOverdue = days < 0 && !tx.isPaid; // only highlight unpaid overdue

    return GestureDetector(
      onLongPress: onAudit,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VaultColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOverdue
                ? VaultColors.neonPink.withValues(alpha: 0.6)
                : VaultColors.neonPurple.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Borrower name
            Text(tx.borrowerName,
                style: VaultFonts.exo(14, weight: FontWeight.w600)),
            const SizedBox(height: 4),
            // Amount + interest and due date
            Text(
              '\$${tx.amountPlusInterest.toStringAsFixed(2)} — '
              'due ${_fmtDate(tx.dueDate)}',
              style: VaultFonts.raj(12, color: VaultColors.textDim),
            ),
            const SizedBox(height: 4),
            // Remaining days or overdue label
            Text(
              isOverdue
                  ? '${-days}d overdue'
                  : tx.isPaid
                      ? 'Paid'
                      : '$days day${days == 1 ? '' : 's'} left',
              style: VaultFonts.raj(12,
                  color: isOverdue
                      ? VaultColors.neonPink
                      : tx.isPaid
                          ? VaultColors.neonTeal
                          : VaultColors.textSecondary),
            ),
            // Show note if present
            if (tx.note != null && tx.note!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Note: ${tx.note}',
                    style: VaultFonts.body(11, color: VaultColors.textDim)),
              ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Dialog for adding/modifying audit information on a transaction.
/// Also allows toggling the paid/unpaid status.
class AuditDialog extends StatefulWidget {
  final LoanTransaction transaction;
  final VoidCallback onSaved; // called after successful save

  const AuditDialog(
      {super.key, required this.transaction, required this.onSaved});

  @override
  State<AuditDialog> createState() => _AuditDialogState();
}

class _AuditDialogState extends State<AuditDialog> {
  late final TextEditingController _noteCtrl;
  late final TextEditingController _refNameCtrl;
  late final TextEditingController _refCodeCtrl;
  late bool _isPaid; // current paid toggle state

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController(text: widget.transaction.note ?? '');
    _refNameCtrl =
        TextEditingController(text: widget.transaction.referralName ?? '');
    _refCodeCtrl =
        TextEditingController(text: widget.transaction.referralCode ?? '');
    _isPaid = widget.transaction.isPaid;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _refNameCtrl.dispose();
    _refCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final db = context.read<DatabaseService>();
    await db.addAudit(
      widget.transaction.id!,
      note: _noteCtrl.text.trim(),
      referralName:
          _refNameCtrl.text.trim().isEmpty ? null : _refNameCtrl.text.trim(),
      referralCode:
          _refCodeCtrl.text.trim().isEmpty ? null : _refCodeCtrl.text.trim(),
      newStatus: _isPaid ? 'paid' : 'unpaid',
    );
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: VaultColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: VaultColors.neonPurple.withValues(alpha: 0.5)),
      ),
      title: Text('AUDIT',
          style: VaultFonts.exo(14, weight: FontWeight.w700)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Paid toggle
            Row(
              children: [
                Text('Paid',
                    style: VaultFonts.body(14,
                        color: VaultColors.textSecondary)),
                const Spacer(),
                Switch(
                  value: _isPaid,
                  activeThumbColor: VaultColors.neonTeal,
                  onChanged: (v) => setState(() => _isPaid = v),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Note'),
              style: VaultFonts.raj(14),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _refNameCtrl,
              decoration:
                  const InputDecoration(labelText: 'Referral Name'),
              style: VaultFonts.raj(14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _refCodeCtrl,
              decoration:
                  const InputDecoration(labelText: 'Referral Code'),
              style: VaultFonts.raj(14),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: VaultFonts.body(13)),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}