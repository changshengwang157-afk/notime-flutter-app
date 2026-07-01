/// HeyNotiMe API — override at build/run time:
/// `flutter run --dart-define=NOTIME_API_BASE=http://10.0.2.2:8000 --dart-define=USE_MOCK_DATA=false`
abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'NOTIME_API_BASE',
    // defaultValue: 'http://10.0.2.2:8000',
    defaultValue: 'https://heynotime.com',
  );

  /// When true, uses local mock data (no Django required).
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: false,
  );

  static String get apiV1 => '$baseUrl/api/v1';

  /// Default integration for logo / fallback connect when QR fails.
  static const String fallbackConnectSlug = String.fromEnvironment(
    'NOTIME_FALLBACK_SLUG',
    defaultValue: 'thescratchify',
  );
}
