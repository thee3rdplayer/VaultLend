import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../services/data_change_notifier.dart';
import '../theme.dart';
import '../widgets.dart';
import 'add_transaction_dialog.dart';

/// Central hub for adding notes to any transaction and creating new loans.
/// The plus button (FAB) lives here.
class AuditTab extends StatefulWidget {
  const AuditTab({super.key});

  @override
  State<AuditTab> createState() => _AuditTabState();
}

class _AuditTabState extends State<AuditTab> {
  String _statusFilter = 'unpaid';
  LoanTransaction? _selected;

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();
    // Rebuild whenever any other tab changes data
    context.watch<DataChangeNotifier>();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: VaultColors.neonPurple,
        onPressed: () async {
          // Capture notifier before async to avoid context‑across‑gap warning
          final notifier = context.read<DataChangeNotifier>();
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) => const AddTransactionDialog()),
          );
          if (added == true) {
            notifier.notifyDataChanged();
          }
        },
        child: const Icon(Icons.add, color: VaultColors.voidBlack),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Dropdown to filter unpaid/paid
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    // Use initialValue instead of the deprecated `value`
                    initialValue: _statusFilter,
                    items: const [
                      DropdownMenuItem(value: 'unpaid', child: Text('Unpaid')),
                      DropdownMenuItem(value: 'paid', child: Text('Paid')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _statusFilter = val!;
                        _selected = null; // reset selection
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Status'),
                    style: VaultFonts.raj(14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // List of matching transactions
            Expanded(
              child: FutureBuilder<List<LoanTransaction>>(
                future: db.getByStatus(_statusFilter),
                builder: (_, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: VaultColors.neonPurple),
                    );
                  }
                  final txs = snapshot.data ?? [];
                  if (txs.isEmpty) {
                    return Center(
                      child: Text(
                        'No $_statusFilter  loans',
                        style: VaultFonts.body(15),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: txs.length,
                    itemBuilder: (_, i) {
                      final tx = txs[i];
                      final isSelected = _selected?.id == tx.id;
                      return ListTile(
                        selected: isSelected,
                        selectedTileColor:
                            // withValues(alpha:) replaces deprecated withOpacity
                            VaultColors.neonPurple.withValues(alpha: 0.1),
                        title: Text(tx.borrowerName,
                            style: VaultFonts.exo(14)),
                        subtitle: Text(
                          // K symbol, totals formatted to 2 decimals
                          'K ${tx.totalToPay.toStringAsFixed(2)}',
                          style: VaultFonts.raj(12),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check,
                                color: VaultColors.neonTeal)
                            : null,
                        onTap: () => setState(() => _selected = tx),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // Button to open audit dialog for the selected transaction
            if (_selected != null)
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AuditDialog(
                      transaction: _selected!,
                      onSaved: () {
                        setState(() => _selected = null);
                        context
                            .read<DataChangeNotifier>()
                            .notifyDataChanged();
                      },
                    ),
                  );
                },
                child: const Text('Add / Edit Note'),
              ),
          ],
        ),
      ),
    );
  }
}