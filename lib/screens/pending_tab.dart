import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../services/data_change_notifier.dart';
import '../theme.dart';
import '../widgets.dart';

/// Lists unpaid loans, sorted by due date (earliest first).
/// Swipe right‑to‑left to mark as paid; long‑press to open audit.
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
    // Listen for global data changes (e.g., from AuditTab or swipe actions)
    context.read<DataChangeNotifier>().addListener(_refresh);
  }

  @override
  void dispose() {
    context.read<DataChangeNotifier>().removeListener(_refresh);
    super.dispose();
  }

  /// Reload the unpaid list from the database.
  void _refresh() {
    final db = context.read<DatabaseService>();
    _future = db.getByStatus('unpaid');
  }

  @override
  Widget build(BuildContext context) {
    // Ensure the widget rebuilds when DataChangeNotifier fires
    context.watch<DataChangeNotifier>();

    return FutureBuilder<List<LoanTransaction>>(
      future: _future,
      builder: (_, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: VaultColors.neonPurple),
          );
        }
        final txs = snapshot.data ?? [];
        if (txs.isEmpty) {
          return Center(
            child: Text('No pending loans', style: VaultFonts.body(15)),
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
                child: const Icon(Icons.check, color: VaultColors.voidBlack),
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
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('No'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Yes'),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (_) async {
                // Capture notifier before async to avoid context‑gap warning
                final notifier = context.read<DataChangeNotifier>();
                await context
                    .read<DatabaseService>()
                    .updateStatus(tx.id!, 'paid');
                notifier.notifyDataChanged();
              },
              child: TransactionTile(
                tx: tx,
                onAudit: () => _openAudit(tx),
              ),
            );
          },
        );
      },
    );
  }

  /// Opens the audit dialog for a specific transaction.
  void _openAudit(LoanTransaction tx) {
    showDialog(
      context: context,
      builder: (_) => AuditDialog(
        transaction: tx,
        onSaved: () {
          context.read<DataChangeNotifier>().notifyDataChanged();
        },
      ),
    );
  }
}