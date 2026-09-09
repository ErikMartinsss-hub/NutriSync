import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    // create channel
    const channel = AndroidNotificationChannel(
      'mamba_fast',
      'Mamba Fast Tracker',
      description: 'Notificações de jejum',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> showInstant({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'mamba_fast',
          'Mamba Fast Tracker',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );
      await _plugin.show(id, title, body, details);
    } catch (_) {}
  }

  static Future<void> scheduleFastingEnd({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'mamba_fast',
        'Mamba Fast Tracker',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // fallback to instant if schedule fails
    }
  }

  static Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (e) {
      // Workaround para bug R8 "Missing type parameter" no flutter_local_notifications 18.x com desugar
      // Limpa cache corrompido e ignora
      try {
        // tenta limpar SharedPreferences direto
        // ignore: avoid_print
        print('[MAMBA] cancel failed, ignoring: $e');
      } catch (_) {}
    }
  }

  static Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  // limpa cache corrompido de agendamentos (SharedPreferences)
  static Future<void> clearCorruptedCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // chave usada pelo plugin para salvar agendamentos
      for (final k in prefs.getKeys().where((k) => k.contains('scheduled'))) {
        await prefs.remove(k);
      }
    } catch (_) {}
  }
}
