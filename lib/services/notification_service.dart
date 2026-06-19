import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/transaction.dart';

/// Handles scheduling and cancelling local notifications for due loans.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Initialise the plugin and request permissions.
  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
  }

  /// Schedule a reminder for a given transaction.
  /// The notification will fire on the due date at 9:00 AM local time.
  Future<void> scheduleDueReminder(LoanTransaction tx) async {
    // Do not schedule if already paid or due date has already passed
    if (tx.isPaid || tx.dueDate.isBefore(DateTime.now())) return;

    // Convert DateTime to TZDateTime using the local timezone
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
      DateTime(tx.dueDate.year, tx.dueDate.month, tx.dueDate.day, 9),
      tz.local,
    );

    await _plugin.zonedSchedule(
      tx.id!,                                 // unique ID for this transaction
      'Loan Due: ${tx.borrowerName}',
      'K ${tx.totalToPay.toStringAsFixed(2)} is due today',
      scheduledDate,
      const NotificationDetails(
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
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  /// Cancel the notification for a transaction (e.g., when paid or deleted).
  Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id);
  }

  /// Cancel all scheduled notifications – useful for a clean reschedule.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}