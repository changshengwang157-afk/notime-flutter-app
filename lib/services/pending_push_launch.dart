import 'package:firebase_messaging/firebase_messaging.dart';

/// Set in `main()` before `runApp` so cold-start notification taps survive
/// iOS lock-screen / passcode / session-restore delays.
RemoteMessage? pendingLaunchPushMessage;
