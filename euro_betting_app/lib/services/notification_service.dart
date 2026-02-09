import 'package:euro_betting_app/services/analysis_engine.dart';
import 'package:euro_betting_app/services/data_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

const backgroundTask = 'fetchDataAndNotify';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == backgroundTask) {
      final dataService = DataService(
        dataUrl:
            'https://raw.githubusercontent.com/shayo91/euroleagueTips/main/euro_betting_app/resources/data.json',
      );
      try {
        final data = await dataService.fetchData();
        final tips = AnalysisEngine.generateTips(
          data.players,
          data.teams,
          data.defenses,
          data.schedule,
        );
        final highConfidenceTips =
            tips.where((tip) => tip.confidenceScore > 0.85).toList();

        if (highConfidenceTips.isNotEmpty) {
          await NotificationService.showNotification(
            title: '🚨 Mismatch Alert',
            body:
                '${highConfidenceTips.first.matchupDescription} is a GREEN LIGHT. Tap to see why.',
          );
        }
        return Future.value(true);
      } catch (e) {
        return Future.value(false);
      }
    }
    return Future.value(false);
  });
}

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _notifications.initialize(settings: settings);
  }

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const android = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    const platform = NotificationDetails(android: android, iOS: ios);
    await _notifications.show(id: 0, title: title, body: body, notificationDetails: platform);
  }

  static Future<void> registerDailyTask() async {
    await Workmanager().registerPeriodicTask(
      backgroundTask,
      backgroundTask,
      frequency: const Duration(days: 1),
    );
  }
}