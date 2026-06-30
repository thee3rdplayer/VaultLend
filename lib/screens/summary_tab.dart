import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../services/data_change_notifier.dart';
import '../theme.dart';

/// Dashboard overview: outstanding total, collected total, overdue count.
/// Listens to DataChangeNotifier to auto‑refresh when data changes elsewhere.
class SummaryTab extends StatefulWidget {
  const SummaryTab({super.key});

  @override
  State<SummaryTab> createState() => _SummaryTabState();
}

class _SummaryTabState extends State<SummaryTab> {
  late Future<List<LoanTransaction>> _future;
  late final DataChangeNotifier _dataNotifier;   // stored reference

  @override
  void initState() {
    super.initState();
    _dataNotifier = context.read<DataChangeNotifier>();
    _dataNotifier.addListener(_refresh);
    _refresh();
  }

  @override
  void dispose() {
    _dataNotifier.removeListener(_refresh);   // safe – uses stored reference
    super.dispose();
  }

  void _refresh() {
    final db = context.read<DatabaseService>();
    _future = db.allTransactions();
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
        final unpaid = txs.where((t) => t.status == 'unpaid').toList();
        final paid = txs.where((t) => t.status == 'paid').toList();

        final totalUnpaid =
            unpaid.fold<double>(0, (sum, t) => sum + t.totalToPay);
        final totalPaid =
            paid.fold<double>(0, (sum, t) => sum + t.totalToPay);

        final now = DateTime.now();
        final overdueCount =
            unpaid.where((t) => t.dueDate.isBefore(now)).length;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _StatCard(
                label: 'OUTSTANDING',
                value: 'K ${totalUnpaid.toStringAsFixed(2)}',
                color: VaultColors.neonPink,
                extra: overdueCount > 0 ? '$overdueCount overdue' : null,
              ),
              const SizedBox(height: 12),
              _StatCard(
                label: 'COLLECTED',
                value: 'K ${totalPaid.toStringAsFixed(2)}',
                color: VaultColors.neonTeal,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final String? extra;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: VaultColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: VaultFonts.raj(12, color: VaultColors.textDim)),
          const SizedBox(height: 8),
          Text(value,
              style: VaultFonts.raj(32,
                  weight: FontWeight.w700, color: color)),
          if (extra != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(extra!,
                  style: VaultFonts.body(13, color: VaultColors.neonPink)),
            ),
        ],
      ),
    );
  }
}