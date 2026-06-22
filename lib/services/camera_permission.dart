import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Requests camera access before opening [mobile_scanner].
///
/// On iOS, [mobile_scanner] shows the system dialog using [NSCameraUsageDescription].
/// Calling [Permission.camera] without Podfile `PERMISSION_CAMERA=1` can crash release builds.
Future<bool> ensureCameraPermission() async {
  if (!kIsWeb && Platform.isIOS) {
    return true;
  }

  final status = await Permission.camera.status;
  if (status.isGranted) return true;
  if (status.isPermanentlyDenied) return false;

  final result = await Permission.camera.request();
  return result.isGranted;
}

Future<bool> isCameraPermanentlyDenied() async {
  if (!kIsWeb && Platform.isIOS) {
    return false;
  }
  return Permission.camera.isPermanentlyDenied;
}

String cameraPermissionMessage(bool permanentlyDenied) {
  if (permanentlyDenied) {
    return 'Camera access is disabled. Enable it in Settings to scan QR codes.';
  }
  return 'Camera permission is required to scan your NotiMe QR code.';
}
