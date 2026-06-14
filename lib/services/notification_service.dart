// lib/services/notification_service.dart
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import '../database_helper.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await AwesomeNotifications().initialize(
      'resource://drawable/launcher_icon', // ← AJOUTE CETTE LIGNE (c'était null avant)

      [
        NotificationChannel(
          channelKey: 'cheque_alerts',
          channelName: 'تنبيهات الشيكات',
          channelDescription: 'تنبيهات عند اقتراب موعد استحقاق الشيك',
          importance: NotificationImportance.High,
          defaultColor: const Color(0xFF1B8A6B),
          ledColor: const Color(0xFF1B8A6B),
          playSound: true,
          enableVibration: true,
          icon:
              'resource://drawable/launcher_icon', // ← AJOUTE CETTE LIGNE AUSSI
        ),
      ],
    );
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    return await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  Future<void> scheduleChequNotification({
    required int chequeId,
    required String chequeNumero,
    required String clientNom,
    required double montant,
    required DateTime dateEcheance,
    required String currency,
  }) async {
    await init();
    final now = DateTime.now();

    final threeDaysBefore = DateTime(
        dateEcheance.year, dateEcheance.month, dateEcheance.day - 3, 9, 0);
    if (threeDaysBefore.isAfter(now)) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: chequeId * 10 + 3,
          channelKey: 'cheque_alerts',
          title: 'تنبيه شيك - $clientNom',
          body:
              'شيك رقم $chequeNumero بقيمة $montant $currency يستحق بعد 3 أيام',
          notificationLayout: NotificationLayout.Default,
        ),
        schedule: NotificationCalendar.fromDate(date: threeDaysBefore),
      );
    }

    final oneDayBefore = DateTime(
        dateEcheance.year, dateEcheance.month, dateEcheance.day - 1, 9, 0);
    if (oneDayBefore.isAfter(now)) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: chequeId * 10 + 1,
          channelKey: 'cheque_alerts',
          title: '⚠️ تنبيه عاجل - $clientNom',
          body: 'شيك رقم $chequeNumero بقيمة $montant $currency يستحق غداً!',
          notificationLayout: NotificationLayout.Default,
        ),
        schedule: NotificationCalendar.fromDate(date: oneDayBefore),
      );
    }

    final onTheDay =
        DateTime(dateEcheance.year, dateEcheance.month, dateEcheance.day, 8, 0);
    if (onTheDay.isAfter(now)) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: chequeId * 10 + 0,
          channelKey: 'cheque_alerts',
          title: '🔴 اليوم هو يوم الاستحقاق - $clientNom',
          body: 'شيك رقم $chequeNumero بقيمة $montant $currency يستحق اليوم!',
          notificationLayout: NotificationLayout.Default,
        ),
        schedule: NotificationCalendar.fromDate(date: onTheDay),
      );
    }
  }

  Future<void> sendTestNotification() async {
    await init();
    final testTime = DateTime.now().add(const Duration(minutes: 1));
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 99999,
        channelKey: 'cheque_alerts',
        title: '✅ تجربة الإشعارات - كارنيه',
        body: 'الإشعارات تشتغل بشكل صحيح! 🎉',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar.fromDate(date: testTime),
    );
  }

  Future<void> cancelChequeNotifications(int chequeId) async {
    await AwesomeNotifications().cancel(chequeId * 10 + 3);
    await AwesomeNotifications().cancel(chequeId * 10 + 1);
    await AwesomeNotifications().cancel(chequeId * 10 + 0);
  }

  Future<void> cancelAll() async {
    await AwesomeNotifications().cancelAll();
    await AwesomeNotifications().cancelAllSchedules();
  }

  Future<void> rescheduleAllFromDb(String currency) async {
    await init();
    await cancelAll();
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT ch.id, ch.numero, ch.montant, ch.dateEcheance, cl.nom as clientNom
      FROM cheques ch
      JOIN credits cr ON ch.creditId = cr.id
      JOIN clients cl ON cr.clientId = cl.id
      WHERE ch.statut = 'EN_ATTENTE'
    ''');
    for (final row in rows) {
      final dateEcheance =
          DateTime.tryParse(row['dateEcheance'] as String? ?? '');
      if (dateEcheance == null) continue;
      if (dateEcheance.isBefore(DateTime.now())) continue;
      await scheduleChequNotification(
        chequeId: row['id'] as int,
        chequeNumero: row['numero'] as String,
        clientNom: row['clientNom'] as String,
        montant: (row['montant'] as num).toDouble(),
        dateEcheance: dateEcheance,
        currency: currency,
      );
    }
  }
}
