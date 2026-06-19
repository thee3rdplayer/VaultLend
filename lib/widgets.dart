import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/transaction.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'theme.dart';

/// A styled tile for displaying a loan transaction.
/// Shows name, phone, address, total, due date, remaining days,
/// overdue highlight, and note.
class TransactionTile extends StatelessWidget {
  final LoanTransaction tx;
  final VoidCallback? onAudit; // called on long‑press to open audit

  const TransactionTile({super.key, required this.tx, this.onAudit});

  @override
  Widget build(BuildContext context) {
    final days = tx.daysUntilDue;
    final isOverdue = days < 0 && !tx.isPaid;

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
            const SizedBox(height: 2),
            // Phone and address (if available)
            if (tx.phone.isNotEmpty || tx.address.isNotEmpty) ...[
              if (tx.phone.isNotEmpty)
                Text('📞 ${tx.phone}',
                    style: VaultFonts.body(12, color: VaultColors.textDim)),
              if (tx.address.isNotEmpty)
                Text('📍 ${tx.address}',
                    style: VaultFonts.body(12, color: VaultColors.textDim)),
              const SizedBox(height: 4),
            ],
            // Amount and due date
            Text(
              'K ${tx.totalToPay.toStringAsFixed(2)} — due ${_fmtDate(tx.dueDate)}',
              style: VaultFonts.raj(12, color: VaultColors.textDim),
            ),
            const SizedBox(height: 4),
            // Remaining days or paid status
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

/// Dialog for editing a loan's note, phone, address, status, and for deletion.
class AuditDialog extends StatefulWidget {
  final LoanTransaction transaction;
  final VoidCallback onSaved; // called after successful save or delete

  const AuditDialog({
    super.key,
    required this.transaction,
    required this.onSaved,
  });

  @override
  State<AuditDialog> createState() => _AuditDialogState();
}

class _AuditDialogState extends State<AuditDialog> {
  late final TextEditingController _noteCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late bool _isPaid;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController(text: widget.transaction.note ?? '');
    _phoneCtrl = TextEditingController(text: widget.transaction.phone);
    _addressCtrl = TextEditingController(text: widget.transaction.address);
    _isPaid = widget.transaction.isPaid;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final db = context.read<DatabaseService>();
    final notif = context.read<NotificationService>();
    await db.addAudit(
      widget.transaction.id!,
      note: _noteCtrl.text.trim(),
      newStatus: _isPaid ? 'paid' : 'unpaid',
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
    );
    // Cancel notification if marked as paid
    if (_isPaid) {
      await notif.cancelReminder(widget.transaction.id!);
    } else {
      // If toggled back to unpaid, reschedule
      await notif.scheduleDueReminder(widget.transaction);
    }
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final db = context.read<DatabaseService>();
    final notif = context.read<NotificationService>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VaultColors.card,
        title: Text('Delete entry?', style: VaultFonts.exo(14)),
        content:
            Text('This cannot be undone.', style: VaultFonts.body(13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await db.delete(widget.transaction.id!);
      await notif.cancelReminder(widget.transaction.id!);
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: VaultColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: VaultColors.neonPurple.withValues(alpha: 0.5)),
      ),
      title: Text('EDIT ENTRY',
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
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
              style: VaultFonts.raj(14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: 'Address'),
              style: VaultFonts.raj(14),
            ),
            const SizedBox(height: 16),
            // Delete button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete Entry'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: VaultColors.neonPink,
                  side: BorderSide(
                      color: VaultColors.neonPink.withValues(alpha: 0.5)),
                ),
                onPressed: _delete,
              ),
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