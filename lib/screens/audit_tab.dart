import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../theme.dart';
import '../widgets.dart';

/// Central hub for adding audit notes/referrals to any transaction.
/// Choose unpaid or paid, then select a specific loan to edit.
class AuditTab extends StatefulWidget {
  const AuditTab({super.key});

  @override
  State<AuditTab> createState() => _AuditTabState();
}

class _AuditTabState extends State<AuditTab> {
  String _statusFilter = 'unpaid'; // default to unpaid
  LoanTransaction? _selected;

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Dropdown to filter by status
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
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
                  return const Center(child: CircularProgressIndicator());
                }
                final txs = snapshot.data ?? [];
                if (txs.isEmpty) {
                  return Center(
                    child: Text(
                      'No $_statusFilter loans',
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
                          VaultColors.neonPurple.withValues(alpha: 0.1),
                      title: Text(tx.borrowerName,
                          style: VaultFonts.exo(14)),
                      subtitle: Text(
                        '\$${tx.amountPlusInterest.toStringAsFixed(2)}',
                        style: VaultFonts.raj(12),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: VaultColors.neonTeal)
                          : null,
                      onTap: () => setState(() => _selected = tx),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Button to open audit dialog for selected transaction
          if (_selected != null)
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AuditDialog(
                    transaction: _selected!,
                    onSaved: () {
                      setState(() => _selected = null);
                    },
                  ),
                );
              },
              child: const Text('Add / Edit Audit'),
            ),
        ],
      ),
    );
  }
}