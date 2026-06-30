import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_init;
import 'auth/auth_service.dart';
import 'auth/login_screen.dart';
import 'global_keys.dart';                              // ← import the key
import 'services/database_service.dart';
import 'services/data_change_notifier.dart';
import 'services/notification_service.dart';
import 'screens/dashboard.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz_init.initializeTimeZones();

  final notificationService = NotificationService();
  await notificationService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => DatabaseService()),
        ChangeNotifierProvider(create: (_) => DataChangeNotifier()),
        Provider(create: (_) => notificationService),
      ],
      child: const VaultLendApp(),
    ),
  );
}

class VaultLendApp extends StatelessWidget {
  const VaultLendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,   // ← attach the global key
      title: 'LuchiKwacha',
      theme: vaultLendTheme(),
      debugShowCheckedModeBanner: false,
      home: Consumer<AuthService>(
        builder: (_, auth, _) {
          if (!auth.isInitialized) {
            return const Scaffold(
              backgroundColor: VaultColors.voidBlack,
              body: Center(
                child: CircularProgressIndicator(color: VaultColors.neonPurple),
              ),
            );
          }
          if (auth.isLocked || auth.needsPinSetup) {
            return const LoginScreen();
          }
          return const Dashboard();
        },
      ),
    );
  }
}