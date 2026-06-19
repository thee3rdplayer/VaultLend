import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../theme.dart';
import '../widgets.dart';
import 'add_transaction_dialog.dart';

/// Displays all unpaid loans, sorted by due date (earliest first).
/// Swipe right‑to‑left to mark as paid; long‑press opens audit.
/// Floating action button to add a new loan.
class PendingTab extends StatefulWidget {
  const PendingTab({super.key});

  @override
  State<PendingTab> createState() => _PendingTabState();
}

class _PendingTabState extends State<PendingTab> {
  late Future<List<LoanTransaction>> _future;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  /// Reload the unpaid list from the database.
  void _refresh() {
    final db = context.read<DatabaseService>();
    _future = db.getByStatus('unpaid');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // FAB to add a new transaction
      floatingActionButton: FloatingActionButton(
        backgroundColor: VaultColors.neonPurple,
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) => const AddTransactionDialog()),
          );
          if (added == true) _refresh();
        },
        child: const Icon(Icons.add, color: VaultColors.voidBlack),
      ),
      body: FutureBuilder<List<LoanTransaction>>(
        future: _future,
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
              child: Text('No pending loans',
                  style: VaultFonts.body(15)),
            );
          }
          return ListView.builder(
            itemCount: txs.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (_, i) {
              final tx = txs[i];
              return Dismissible(
                key: Key(tx.id.toString()),
                direction: DismissDirection.endToStart,
                // Swipe background – teal with check
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: VaultColors.neonTeal,
                  child: const Icon(Icons.check,
                      color: VaultColors.voidBlack),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: VaultColors.card,
                      title: Text('Mark as paid?',
                          style: VaultFonts.exo(14)),
                      content: Text(tx.borrowerName,
                          style: VaultFonts.body(13)),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(ctx, false),
                          child: const Text('No'),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.pop(ctx, true),
                          child: const Text('Yes'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) async {
                  await context
                      .read<DatabaseService>()
                      .updateStatus(tx.id!, 'paid');
                  _refresh();
                },
                child: TransactionTile(
                  tx: tx,
                  onAudit: () => _openAudit(tx),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openAudit(LoanTransaction tx) {
    showDialog(
      context: context,
      builder: (_) => AuditDialog(
        transaction: tx,
        onSaved: _refresh,
      ),
    );
  }
}