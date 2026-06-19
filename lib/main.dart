import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth/auth_service.dart';
import 'auth/login_screen.dart';
import 'services/database_service.dart';
import 'screens/dashboard.dart';
import 'theme.dart';

void main() {
  // Wrap the app with providers for AuthService and DatabaseService
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => DatabaseService()),
      ],
      child: const VaultLendApp(),
    ),
  );
}

/// Root widget. Decides between login and dashboard based on lock state.
class VaultLendApp extends StatelessWidget {
  const VaultLendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VaultLend',
      theme: vaultLendTheme(),             // retro purple neon theme
      debugShowCheckedModeBanner: false,
      home: Consumer<AuthService>(
        builder: (_, auth, __) =>
            auth.isLocked ? const LoginScreen() : const Dashboard(),
      ),
    );
  }
}