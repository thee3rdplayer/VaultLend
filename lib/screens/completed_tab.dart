import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../services/data_change_notifier.dart';
import '../theme.dart';
import '../widgets.dart';

/// Lists paid loans. Long‑press to edit note or revert to unpaid via audit dialog.
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
    context.read<DataChangeNotifier>().addListener(_refresh);
  }

  @override
  void dispose() {
    context.read<DataChangeNotifier>().removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    final db = context.read<DatabaseService>();
    _future = db.getByStatus('paid');
  }

  @override
  Widget build(BuildContext context) {
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
        onSaved: () {
          context.read<DataChangeNotifier>().notifyDataChanged();
        },
      ),
    );
  }
}