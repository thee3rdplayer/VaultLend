import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_service.dart';
import '../auth/change_pin_dialog.dart';
import '../theme.dart';
import 'summary_tab.dart';
import 'pending_tab.dart';
import 'completed_tab.dart';
import 'audit_tab.dart';
import 'upload_tab.dart';

/// Main shell with bottom navigation and locked‑screen timeout handling.
class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _currentIndex = 0;

  // The five main sections of the app
  final _tabs = const [
    SummaryTab(),
    PendingTab(),
    CompletedTab(),  // shows paid loans
    AuditTab(),
    UploadTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Listener(
      // Every pointer down event resets the idle timer
      onPointerDown: (_) => context.read<AuthService>().onUserInteraction(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('VAULT-LEND',
              style: VaultFonts.exo(18, weight: FontWeight.w700)),
          actions: [
            // Change PIN button
            IconButton(
              icon: const Icon(Icons.lock_outline,
                  color: VaultColors.neonPink),
              tooltip: 'Change PIN',
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const ChangePinDialog(),
              ),
            ),
            // Manual lock button
            IconButton(
              icon: const Icon(Icons.logout,
                  color: VaultColors.neonPurple),
              tooltip: 'Lock app',
              onPressed: () => context.read<AuthService>().logout(),
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