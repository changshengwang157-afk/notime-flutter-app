import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../api/notime_api_client.dart';

/// Registers FCM when Firebase is configured (google-services.json / GoogleService-Info.plist).
class PushService {
  PushService({required NotiMeApiClient api}) : _api = api;

  final NotiMeApiClient _api;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token != null) {
        await _api.registerDevice(
          fcmToken: token,
          platform: defaultTargetPlatform.name,
        );
      }
      _initialized = true;
    } catch (e) {
      debugPrint('FCM not configured yet: $e');
    }
  }
}
