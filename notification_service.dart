import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {},
    );

    // Создаём канал для Android
    const channel = AndroidNotificationChannel(
      'sber_alerts',
      'Алерты по SBER',
      description: 'Уведомления о сильном росте или падении акций Сбербанка',
      importance: Importance.high,
      playSound: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'sber_alerts',
      'Алерты по SBER',
      channelDescription: 'Уведомления о сильном росте или падении',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  /// Проверяет пороги и отправляет уведомление при необходимости
  Future<void> checkAndNotify(Map<String, dynamic> priceData) async {
    final prefs = await SharedPreferences.getInstance();
    final threshold = prefs.getDouble('alert_threshold') ?? 2.0;
    final lastNotifiedChange = prefs.getDouble('last_notified_change') ?? 0.0;

    final change = (priceData['LASTCHANGEPRCNT'] as num?)?.toDouble() ?? 0.0;
    final price = (priceData['LAST'] as num?)?.toDouble() ?? 0.0;

    // Избегаем спама: уведомляем только если изменение существенно отличается
    if ((change - lastNotifiedChange).abs() < 0.3) return;

    if (change.abs() >= threshold) {
      final direction = change > 0 ? 'рост' : 'падение';
      final emoji = change > 0 ? '📈' : '📉';

      await showNotification(
        title: '$emoji SBER: сильный $direction!',
        body: 'Изменение: ${change.toStringAsFixed(2)}%\n'
            'Текущая цена: ${price.toStringAsFixed(2)} ₽',
      );

      await prefs.setDouble('last_notified_change', change);
    }
  }
}
