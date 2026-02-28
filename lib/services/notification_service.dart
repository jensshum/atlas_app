import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _controlId = 1;
  static bool _initialized = false;

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
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        await android.requestNotificationsPermission();
        // Create the notification channel explicitly.
        await android.createNotificationChannel(
          const AndroidNotificationChannel(
            'atlas_control',
            'Atlas Control',
            description: 'Shown while Atlas is controlling your phone',
            importance: Importance.max,
          ),
        );
      }
    }

    _initialized = true;
    debugPrint('[NotificationService] initialized');
  }

  static void _onResponse(NotificationResponse response) {
    onCancelTapped?.call();
  }

  static Future<void> showControlNotification() async {
    if (!_initialized) {
      debugPrint('[NotificationService] not initialized, skipping show');
      return;
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'atlas_control',
        'Atlas Control',
        channelDescription: 'Shown while Atlas is controlling your phone',
        importance: Importance.max,
        priority: Priority.max,
        ongoing: true,
        autoCancel: false,
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
    debugPrint('[NotificationService] notification shown');
  }

  static Future<void> cancelControlNotification() async {
    await _plugin.cancel(_controlId);
  }
}
