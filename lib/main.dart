import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'app/notime_app.dart';
import 'firebase_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Never block runApp on push/FCM — a slow or missing Firebase config on iOS
  // TestFlight was leaving users on a blank white launch screen.
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 5));
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase init skipped: $e');
  }

  runApp(const NotiMeApp());
}
