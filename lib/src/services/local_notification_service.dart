import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mobile/src/models/agent_models.dart';

class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: darwin);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<void> showNewDialogNotification(AgentConversationRow row) async {
    if (!_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      'new_dialogs',
      'New dialogs',
      channelDescription: 'Notifications about new dialogs in agent workspace',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iOSDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iOSDetails);

    final title = row.title.trim().isEmpty ? 'Новый диалог' : row.title;
    final body = (row.preview?.trim().isNotEmpty ?? false)
        ? row.preview!.trim()
        : 'Появился новый диалог';

    await _plugin.show(row.id, title, body, details);
  }
}
