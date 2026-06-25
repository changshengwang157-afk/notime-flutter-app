import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../api/notime_api_client.dart';

typedef PushTapCallback = Future<void> Function(Map<String, String> data);

/// FCM registration, foreground banners, and tap routing.
class PushService {
  PushService({required NotiMeApiClient api}) : _api = api;

  final NotiMeApiClient _api;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Custom sound from android/app/src/main/res/raw/notification.wav
  static const RawResourceAndroidNotificationSound _alertSound =
      RawResourceAndroidNotificationSound('notification');

  /// Channel id must change when sound settings change (Android locks channels).
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'notime_push_custom',
    'NotiMe Alerts',
    description: 'Scratch card alerts with custom sound',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    sound: _alertSound,
  );

  bool _configured = false;
  PushTapCallback? _onTap;

  /// Wire Firebase + local notifications. Safe to call once at app startup.
  Future<void> configure({required PushTapCallback onTap}) async {
    if (_configured) return;
    _onTap = onTap;
    try {
      await Firebase.initializeApp();
      await _setupLocalNotifications();

      final messaging = FirebaseMessaging.instance;
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteTap);
      FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);

      _configured = true;
    } catch (e) {
      debugPrint('FCM not configured (add google-services.json): $e');
    }
  }

  /// Register device token after login or session restore.
  Future<void> registerDevice() async {
    if (!_configured) return;
    try {
      // iOS: FCM needs an APNS token before getToken() returns a value.
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        for (var attempt = 0; attempt < 10; attempt++) {
          final apns = await FirebaseMessaging.instance.getAPNSToken();
          if (apns != null) break;
          await Future<void>.delayed(const Duration(milliseconds: 400));
        }
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _registerToken(token);
      } else {
        debugPrint('FCM getToken returned null (${defaultTargetPlatform.name})');
      }
    } catch (e) {
      debugPrint('FCM token register failed: $e');
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      await _api.registerDevice(
        fcmToken: token,
        platform: defaultTargetPlatform.name,
      );
    } catch (e) {
      debugPrint('FCM token register failed: $e');
    }
  }

  /// Handle cold-start tap (app opened from notification tray).
  Future<void> processInitialMessage() async {
    if (!_configured) return;
    try {
      final message = await FirebaseMessaging.instance.getInitialMessage();
      if (message != null) {
        await _handleRemoteTap(message);
      }
    } catch (e) {
      debugPrint('FCM initial message: $e');
    }
  }

  Future<void> _setupLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) {
          _handlePayloadTap(payload);
        }
      },
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? 'NotiMe';
    final body = notification?.body ?? '';
    final payload = jsonEncode(message.data);

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          sound: _alertSound,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  Future<void> _handleRemoteTap(RemoteMessage message) async {
    await _dispatchTap(_normalizeData(message.data));
  }

  void _handlePayloadTap(String payload) {
    try {
      final raw = jsonDecode(payload) as Map<String, dynamic>;
      final data = raw.map((k, v) => MapEntry(k, '$v'));
      _dispatchTap(data);
    } catch (e) {
      debugPrint('Invalid notification payload: $e');
    }
  }

  Future<void> _dispatchTap(Map<String, String> data) async {
    final handler = _onTap;
    if (handler == null) return;
    await handler(data);
  }

  Map<String, String> _normalizeData(Map<String, dynamic> data) {
    return data.map((key, value) => MapEntry(key, '$value'));
  }
}
