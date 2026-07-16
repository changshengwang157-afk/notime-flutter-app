import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'app/notime_app.dart';
import 'firebase_background.dart';
import 'services/pending_push_launch.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  try {
    await Firebase.initializeApp();
    // Read ASAP — before AppState / router / session restore delays.
    // Critical for cold-start taps on Android (killed) and iOS (lock + passcode).
    pendingLaunchPushMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (pendingLaunchPushMessage != null) {
      debugPrint(
        'FCM cold-start tap captured early: '
        'id=${pendingLaunchPushMessage!.messageId} '
        'data=${pendingLaunchPushMessage!.data}',
      );
    }
  } catch (e) {
    debugPrint('Firebase init / initial message: $e');
  }

  runApp(const NotiMeApp());
}
