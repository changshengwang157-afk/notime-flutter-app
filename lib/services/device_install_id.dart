import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stable per-install id sent with fallback connect (no QR token).
class DeviceInstallId {
  DeviceInstallId({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'notime_device_install_id';

  final FlutterSecureStorage _storage;

  Future<String> get() async {
    final existing = await _storage.read(key: _key);
    if (existing != null && existing.isNotEmpty) return existing;

    final id = _generate();
    await _storage.write(key: _key, value: id);
    return id;
  }

  static String _generate() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }
}
