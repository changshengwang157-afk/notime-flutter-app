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

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'notime_push',
    'NotiMe Notifications',
    description: 'Scratch card alerts and updates',
    importance: Importance.high,
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
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _registerToken(token);
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
    await _localNotifications.initialize(
      const InitializationSettings(android: android),
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
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
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
