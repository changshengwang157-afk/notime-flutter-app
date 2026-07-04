import 'package:flutter/material.dart';

/// Global messenger so success/error snackbars survive route changes
/// (e.g. showing a message right after navigating from login to home).
final GlobalKey<ScaffoldMessengerState> appMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void showAppSnack(String message) {
  final messenger = appMessengerKey.currentState;
  if (messenger == null) return;
  messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(message)));
}
