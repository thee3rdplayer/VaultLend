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
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => DatabaseService()),
        ChangeNotifierProvider(create: (_) => DataChangeNotifier()),
      ],
      child: const VaultLendApp(),
    ),
  );
}

/// Root widget – shows a splash while the auth service initialises,
/// then either the login/setup screen or the dashboard.
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
          // Wait until the stored PIN is read
          if (!auth.isInitialized) {
            return const Scaffold(
              backgroundColor: VaultColors.voidBlack,
              body: Center(
                child: CircularProgressIndicator(color: VaultColors.neonPurple),
              ),
            );
          }
          // After init, decide between login/setup and dashboard
          if (auth.isLocked || auth.needsPinSetup) {
            return const LoginScreen();
          }
          return const Dashboard();
        },
      ),
    );
  }
}