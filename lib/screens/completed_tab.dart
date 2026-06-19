import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../theme.dart';
import '../widgets.dart';

/// Displays all paid loans (status = 'paid').
/// Long‑press to open audit and optionally revert to unpaid.
class CompletedTab extends StatefulWidget {
  const CompletedTab({super.key});

  @override
  State<CompletedTab> createState() => _CompletedTabState();
}

class _CompletedTabState extends State<CompletedTab> {
  late Future<List<LoanTransaction>> _future;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    final db = context.read<DatabaseService>();
    _future = db.getByStatus('paid');
  }

  @override
  Widget build(BuildContext context) {
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
            child: Text('No paid loans yet', style: VaultFonts.body(15)),
          );
        }
        return ListView.builder(
          itemCount: txs.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (_, i) {
            final tx = txs[i];
            return TransactionTile(
              tx: tx,
              onAudit: () => _openAudit(tx),
            );
          },
        );
      },
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