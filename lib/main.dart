import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth/auth_service.dart';
import 'auth/login_screen.dart';
import 'services/database_service.dart';
import 'services/data_change_notifier.dart';
import 'screens/dashboard.dart';
import 'theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        // PIN auth & timeout
        ChangeNotifierProvider(create: (_) => AuthService()),
        // SQLite database
        Provider(create: (_) => DatabaseService()),
        // Global data change bus for auto‑refresh
        ChangeNotifierProvider(create: (_) => DataChangeNotifier()),
      ],
      child: const VaultLendApp(),
    ),
  );
}

/// Root widget – shows login/setup if the app is locked or no PIN exists,
/// otherwise the main dashboard.
class VaultLendApp extends StatelessWidget {
  const VaultLendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VaultLend',
      theme: vaultLendTheme(),
      debugShowCheckedModeBanner: false,
      home: Consumer<AuthService>(
        builder: (_, auth, __) {
          // Show login/setup screen if app is locked or no PIN has been set yet
          if (auth.isLocked || auth.needsPinSetup) {
            return const LoginScreen();
          }
          return const Dashboard();
        },
      ),
    );
  }
}