import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionStorage {
  SessionStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _keyAccess = 'notime_access_token';
  static const _keyUserToken = 'notime_user_token';

  final FlutterSecureStorage _storage;

  Future<void> save({
    required String accessToken,
    required String userToken,
  }) async {
    await _storage.write(key: _keyAccess, value: accessToken);
    await _storage.write(key: _keyUserToken, value: userToken);
  }

  Future<({String access, String user})?> read() async {
    final access = await _storage.read(key: _keyAccess);
    final user = await _storage.read(key: _keyUserToken);
    if (access == null || user == null) return null;
    return (access: access, user: user);
  }

  Future<void> clear() async {
    await _storage.delete(key: _keyAccess);
    await _storage.delete(key: _keyUserToken);
  }
}
