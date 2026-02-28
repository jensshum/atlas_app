import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _controlId = 1;

  /// Called when the user taps the "Atlas is controlling" notification.
  static void Function()? onCancelTapped;

  static Future<void> init() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onResponse,
    );

    // Request notification permission on Android 13+.
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  static void _onResponse(NotificationResponse response) {
    onCancelTapped?.call();
  }

  static Future<void> showControlNotification() async {
    // Don't attempt if permission wasn't granted.
    if (!await Permission.notification.isGranted) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'atlas_control',
        'Atlas Control',
        channelDescription: 'Shown while Atlas is controlling your phone',
        importance: Importance.max,
        priority: Priority.max,
        ongoing: true,
        autoCancel: true,
        showWhen: false,
        icon: 'ic_notification',
      ),
    );
    await _plugin.show(
      _controlId,
      'Atlas is controlling your phone',
      'Tap to cancel and take back control',
      details,
    );
  }

  static Future<void> cancelControlNotification() async {
    await _plugin.cancel(_controlId);
  }
}
