import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _controlId = 1;
  static bool _initialized = false;
  static bool _permissionGranted = false;

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

    if (Platform.isAndroid) {
      // Request via permission_handler (works reliably across Android versions).
      var status = await Permission.notification.status;
      debugPrint('[NotificationService] initial permission status: $status');
      if (!status.isGranted) {
        status = await Permission.notification.request();
        debugPrint('[NotificationService] after request: $status');
      }
      _permissionGranted = status.isGranted;

      // Create the notification channel explicitly (required Android 8+).
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        await android.createNotificationChannel(
          const AndroidNotificationChannel(
            'atlas_control',
            'Atlas Control',
            description: 'Shown while Atlas is controlling your phone',
            importance: Importance.max,
          ),
        );
      }
    } else {
      _permissionGranted = true;
    }

    _initialized = true;
    debugPrint('[NotificationService] initialized, permission=$_permissionGranted');
  }

  static void _onResponse(NotificationResponse response) {
    onCancelTapped?.call();
  }

  static Future<void> showControlNotification() async {
    debugPrint('[NotificationService] showControlNotification called, init=$_initialized, perm=$_permissionGranted');

    if (!_initialized || !_permissionGranted) return;

    try {
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
      debugPrint('[NotificationService] notification shown successfully');
    } catch (e) {
      debugPrint('[NotificationService] show failed: $e');
    }
  }

  static Future<void> cancelControlNotification() async {
    await _plugin.cancel(_controlId);
  }
}
