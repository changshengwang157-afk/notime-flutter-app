import 'package:permission_handler/permission_handler.dart';

/// Requests camera access before opening [mobile_scanner].
Future<bool> ensureCameraPermission() async {
  final status = await Permission.camera.status;
  if (status.isGranted) return true;
  if (status.isPermanentlyDenied) return false;

  final result = await Permission.camera.request();
  return result.isGranted;
}

String cameraPermissionMessage(bool permanentlyDenied) {
  if (permanentlyDenied) {
    return 'Camera access is disabled. Enable it in Settings to scan QR codes.';
  }
  return 'Camera permission is required to scan your NotiMe QR code.';
}
