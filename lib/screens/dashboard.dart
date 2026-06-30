import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_service.dart';
import '../auth/change_pin_dialog.dart';
import '../services/database_service.dart';
import '../services/data_change_notifier.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import 'summary_tab.dart';
import 'pending_tab.dart';
import 'completed_tab.dart';
import 'audit_tab.dart';
import 'upload_tab.dart';

/// Main shell with bottom navigation.
/// Listens for pointer events to reset the idle timer.
class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _currentIndex = 0;
  Timer? _overdueTimer;
  late final DataChangeNotifier _dataNotifier;

  final _tabs = const [
    SummaryTab(),
    PendingTab(),
    CompletedTab(),
    AuditTab(),
    UploadTab(),
  ];

  @override
  void initState() {
    super.initState();
    _dataNotifier = context.read<DataChangeNotifier>();

    _rescheduleAllDueReminders();

    _overdueTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        _dataNotifier.notifyDataChanged();
      }
    });
  }

  @override
  void dispose() {
    _overdueTimer?.cancel();
    super.dispose();
  }

  void _rescheduleAllDueReminders() {
    final db = context.read<DatabaseService>();
    final notif = context.read<NotificationService>();
    db.allTransactions().then((txs) {
      for (final tx in txs) {
        if (!tx.isPaid) {
          notif.scheduleDueReminder(tx);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => context.read<AuthService>().onUserInteraction(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('LUCHI-KWACHA',
              style: VaultFonts.exo(18, weight: FontWeight.w700)),
          actions: [
            IconButton(
              icon: const Icon(Icons.lock_outline,
                  color: VaultColors.neonPink),
              tooltip: 'Change PIN',
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const ChangePinDialog(),
              ),
            ),
          ],
        ),
        body: IndexedStack(index: _currentIndex, children: _tabs),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          selectedItemColor: VaultColors.neonPurple,
          unselectedItemColor: VaultColors.textDim,
          backgroundColor: VaultColors.surface,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.pie_chart), label: 'Summary'),
            BottomNavigationBarItem(
                icon: Icon(Icons.hourglass_bottom), label: 'Pending'),
            BottomNavigationBarItem(
                icon: Icon(Icons.check_circle), label: 'Paid'),
            BottomNavigationBarItem(
                icon: Icon(Icons.assignment), label: 'Audit'),
            BottomNavigationBarItem(
                icon: Icon(Icons.cloud_upload), label: 'Upload'),
          ],
        ),
      ),
    );
  }
}