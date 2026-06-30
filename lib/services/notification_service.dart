import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/transaction.dart';

/// Handles scheduling and cancelling local notifications for due loans.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'vaultlend_due',
      'Due Reminders',
      description: 'Loan due date alerts',
      importance: Importance.high,
    );
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
      await androidPlugin.requestNotificationsPermission();
    }

    debugPrint('>>> NotificationService initialised');
  }

  /// **Production**: schedule a reminder 30 days after creation.
  Future<void> scheduleDueReminder(LoanTransaction tx) async {
    if (tx.isPaid) return;

    final DateTime notifyDateTime = tx.createdAt.add(const Duration(days: 30));
    if (notifyDateTime.isBefore(DateTime.now())) return;

    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
      notifyDateTime,
      tz.local,
    );

    await _plugin.zonedSchedule(
      id: tx.id!,
      title: 'Loan Due: ${tx.borrowerName}',
      body: 'K ${tx.totalToPay.toStringAsFixed(2)} may be due for follow‑up',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        iOS: DarwinNotificationDetails(
          sound: 'default',
          badgeNumber: 1,
        ),
        android: AndroidNotificationDetails(
          'vaultlend_due',
          'Due Reminders',
          channelDescription: 'Loan due date alerts',
          importance: Importance.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexact,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  /// **Test helper**: fires an immediate notification using `show()`.
  Future<void> showTestNotification() async {
    await _plugin.show(
      id: 99999,
      title: 'VaultLend Test',
      body: 'Notifications are working!',
      notificationDetails: const NotificationDetails(
        iOS: DarwinNotificationDetails(sound: 'default'),
        android: AndroidNotificationDetails(
          'vaultlend_due',
          'Due Reminders',
          channelDescription: 'Loan due date alerts',
          importance: Importance.high,
        ),
      ),
    );
  }

  Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}