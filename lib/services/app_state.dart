import 'dart:async';

import 'package:flutter/widgets.dart';

import '../api/notime_api_client.dart';
import '../config/api_config.dart';
import '../core/notime_branding.dart';
import '../data/mock_data.dart';
import '../models/connected_app.dart';
import '../models/notification_item.dart';
import '../models/sent_notification.dart';
import '../models/user_session.dart';
import 'device_install_id.dart';
import 'deep_link_service.dart';
import 'push_service.dart';
import 'session_storage.dart';

typedef PushNavigateCallback = void Function(
  String location, {
  bool usePush,
});

class AppState extends ChangeNotifier {
  AppState() {
    _restoreSession().whenComplete(_completeReady);
  }

  final Completer<void> _readyCompleter = Completer<void>();
  Future<void> get ready => _readyCompleter.future;

  void _completeReady() {
    if (!_readyCompleter.isCompleted) {
      _readyCompleter.complete();
    }
  }

  final SessionStorage _storage = SessionStorage();
  final DeviceInstallId _deviceInstallId = DeviceInstallId();
  final NotiMeApiClient _api = NotiMeApiClient();
  late final PushService _push = PushService(api: _api);
  final DeepLinkService _deepLinks = DeepLinkService();
  PushNavigateCallback? _onPushNavigate;
  Map<String, String>? _pendingPushData;

  UserSession? _session;
  final List<ConnectedApp> _connectedApps = [];
  final Map<String, List<NotificationItem>> _notificationsByApp = {};
  List<SentNotification> _history = [...MockData.initialHistory];
  String? _selectedAppId;
  bool _loading = false;
  String? _error;
  String? _lastSuccessMessage;

  UserSession? get session => _session;
  bool get isLoggedIn => _session != null;
  bool get isLoading => _loading;
  String? get error => _error;
  String? get lastSuccessMessage => _lastSuccessMessage;
  List<ConnectedApp> get connectedApps => List.unmodifiable(_connectedApps);
  List<SentNotification> get history => List.unmodifiable(_history);

  ConnectedApp? get selectedApp {
    if (_selectedAppId == null && _connectedApps.isNotEmpty) {
      return _connectedApps.first;
    }
    try {
      return _connectedApps.firstWhere((a) => a.id == _selectedAppId);
    } catch (_) {
      return _connectedApps.isNotEmpty ? _connectedApps.first : null;
    }
  }

  ConnectedApp? connectedAppById(String appId) {
    try {
      return _connectedApps.firstWhere((a) => a.id == appId);
    } catch (_) {
      return MockData.appById(appId);
    }
  }

  List<NotificationItem> notificationsForApp(String appId) {
    if (ApiConfig.useMockData) {
      return MockData.notificationsForApp(appId);
    }
    return _notificationsByApp[appId] ?? [];
  }

  List<NotificationItem> notificationsForSelectedApp() {
    final app = selectedApp;
    if (app == null) return [];
    return notificationsForApp(app.id);
  }

  NotificationItem? notificationById(String id) {
    for (final list in _notificationsByApp.values) {
      for (final n in list) {
        if (n.id == id) return n;
      }
    }
    if (ApiConfig.useMockData) {
      for (final app in _connectedApps) {
        for (final n in MockData.notificationsForApp(app.id)) {
          if (n.id == id) return n;
        }
      }
    }
    return null;
  }

  Future<LoginResult> loginFromQrPayload(String raw) async {
    final parsed = parsePairingPayload(raw);
    if (parsed == null) return LoginResult.invalidQr;

    if (parsed.token == 'invalid' || parsed.token == 'not-found') {
      return LoginResult.accountNotFound;
    }

    if (ApiConfig.useMockData) {
      return _loginMock(parsed.slug, parsed.token);
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.pair(slug: parsed.slug, token: parsed.token);
      return await _completePairResult(result);
    } on NotiMeApiException catch (e) {
      _error = e.message;
      if (e.statusCode == 404 || e.statusCode == 400) {
        return LoginResult.invalidQr;
      }
      return LoginResult.invalidQr;
    } catch (e) {
      // SocketException / ClientException / TimeoutException etc. — the server
      // was unreachable (e.g. wrong NOTIME_API_BASE or no connectivity).
      _error = 'Could not reach the server. Check your connection and try again.';
      return LoginResult.networkError;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Fallback connect when QR scan fails — slug + stable device id.
  Future<LoginResult> loginFallbackConnect(String slug) async {
    final normalized = slug.trim().toLowerCase();
    if (normalized.isEmpty) return LoginResult.invalidQr;

    if (ApiConfig.useMockData) {
      return _loginMock(normalized, 'fallback');
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final deviceId = await _deviceInstallId.get();
      final result = await _api.pairFallback(
        slug: normalized,
        deviceId: deviceId,
      );
      return await _completePairResult(result);
    } on NotiMeApiException catch (e) {
      _error = e.message;
      if (e.statusCode == 403) {
        _error =
            'Continue without QR is disabled for this app. '
            'Use Paste pairing URL with the link from Dashboard → My Users.';
        return LoginResult.networkError;
      }
      if (e.statusCode == 404) {
        return LoginResult.invalidQr;
      }
      if (e.statusCode == 429) {
        _error = 'Too many connect attempts. Please try again later.';
      }
      return LoginResult.networkError;
    } catch (_) {
      _error = 'Could not reach the server. Check your connection and try again.';
      return LoginResult.networkError;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<LoginResult> _completePairResult(PairResult result) async {
    _api.setAccessToken(result.accessToken);
    await _storage.save(
      accessToken: result.accessToken,
      userToken: result.userToken,
    );
    _session = UserSession(
      userToken: result.userToken,
      displayName: 'User',
    );
    _connectedApps.clear();
    _connectedApps.add(result.integration);
    _selectedAppId = result.integration.id;
    _notificationsByApp.clear();
    _history = [];
    _lastSuccessMessage = result.message;
    await refreshFromApi();
    await _push.registerDevice();
    await _processPendingPush();
    return LoginResult.success;
  }

  void clearLastSuccessMessage() {
    _lastSuccessMessage = null;
  }

  LoginResult _loginMock(String project, String userToken) {
    _session = UserSession(userToken: userToken, displayName: 'User');
    final app = _appForProject(project);
    _seedDefaultConnectedApps();
    if (!_connectedApps.any((a) => a.id == app.id)) {
      _connectedApps.add(app);
    }
    _selectedAppId = app.id;
    notifyListeners();
    return LoginResult.success;
  }

  Future<ConnectAppResult> connectAppFromQr(String raw) async {
    if (!isLoggedIn) return ConnectAppResult.notLoggedIn;

    final parsed = parsePairingPayload(raw);
    if (parsed == null) return ConnectAppResult.invalidQr;

    if (ApiConfig.useMockData) {
      final app = _appForProject(parsed.slug);
      if (_connectedApps.any((a) => a.id == app.id)) {
        return ConnectAppResult.alreadyConnected;
      }
      _connectedApps.add(app);
      _selectedAppId = app.id;
      notifyListeners();
      return ConnectAppResult.success;
    }

    try {
      final result = await _api.pair(slug: parsed.slug, token: parsed.token);
      if (_connectedApps.any((a) => a.id == result.integration.id)) {
        return ConnectAppResult.alreadyConnected;
      }
      _connectedApps.add(result.integration);
      _selectedAppId = result.integration.id;
      await _loadNotifications(result.integration.id);
      notifyListeners();
      return ConnectAppResult.success;
    } on NotiMeApiException {
      return ConnectAppResult.invalidQr;
    } catch (_) {
      // Server unreachable (wrong NOTIME_API_BASE or no connectivity).
      return ConnectAppResult.networkError;
    }
  }

  /// Called once from [NotiMeApp] — wires FCM tap → in-app notification detail.
  Future<void> setupPushHandlers({
    required PushNavigateCallback onNavigate,
  }) async {
    _onPushNavigate = onNavigate;
    await _push.configure(onTap: _handlePushTap);
    await ready;
    // Let GoRouter finish its first redirect (e.g. / → /home) before cold-start tap.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await _push.processInitialMessage();
    await _processPendingPush();
  }

  /// Universal / app links: pairing URLs and /connect/{slug} fallback.
  void setupDeepLinks({
    required Future<void> Function(String payload) onPairingUrl,
    required Future<void> Function(String slug) onConnectSlug,
  }) {
    _deepLinks.listen(
      onPairingUrl: (payload) => unawaited(() async {
        await ready;
        await onPairingUrl(payload);
      }()),
      onConnectSlug: (slug) => unawaited(() async {
        await ready;
        await onConnectSlug(slug);
      }()),
    );
  }

  @override
  void dispose() {
    _deepLinks.dispose();
    super.dispose();
  }

  Future<void> _handlePushTap(Map<String, String> data) async {
    if (ApiConfig.useMockData) return;

    if (!isLoggedIn) {
      _pendingPushData = Map<String, String>.from(data);
      return;
    }

    await _openNotificationFromPush(data);
  }

  Future<void> _processPendingPush() async {
    final pending = _pendingPushData;
    if (pending == null || !isLoggedIn) return;
    _pendingPushData = null;
    await _openNotificationFromPush(pending);
  }

  /// Loads a notification from the API and caches it for the inbox + detail screen.
  Future<NotificationItem> fetchAndCacheNotification(String deliveryId) async {
    final item = await _api.fetchNotificationDetail(deliveryId);
    _cacheNotification(item);
    notifyListeners();
    return item;
  }

  Future<void> _openNotificationFromPush(Map<String, String> data) async {
    var deliveryId = data['delivery_id']?.trim();
    final slug = data['integration_slug']?.trim();

    if (slug != null && slug.isNotEmpty) {
      _selectedAppId = slug;
    }

    if (deliveryId == null || deliveryId.isEmpty) {
      debugPrint('Push tap: missing delivery_id — data=$data');
      // Only hit the network for a fallback id when the payload omitted it.
      try {
        await refreshFromApi();
      } catch (e) {
        debugPrint('Push tap inbox refresh failed: $e');
      }
      final latest = notificationsForSelectedApp();
      if (latest.isNotEmpty) {
        deliveryId = latest.first.id;
        debugPrint('Push tap: falling back to latest inbox id=$deliveryId');
      } else {
        final homeSlug = slug ?? selectedApp?.id;
        if (homeSlug != null && homeSlug.isNotEmpty) {
          _navigateFromPush('/home/$homeSlug');
        }
        return;
      }
    }

    // Prefetch detail so the screen has content; do not refresh the whole
    // inbox first — that notifyListeners race used to cancel detail navigation.
    try {
      await fetchAndCacheNotification(deliveryId);
    } catch (e) {
      debugPrint('Push tap detail load failed: $e');
    }

    _navigateFromPush('/notification/$deliveryId');

    // Refresh inbox in the background after navigation is scheduled.
    unawaited(refreshFromApi().catchError((Object e) {
      debugPrint('Push tap background refresh failed: $e');
    }));
  }

  void _navigateFromPush(String location, {bool usePush = false}) {
    final navigate = _onPushNavigate;
    if (navigate == null) {
      debugPrint('Push navigation skipped: handler not ready ($location)');
      return;
    }

    // Run after the current frame so we are not mid-GoRouter refresh.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(Future<void>(() async {
        navigate(location, usePush: usePush);
      }));
    });
  }

  void _cacheNotification(NotificationItem item) {
    final list = _notificationsByApp.putIfAbsent(item.appId, () => []);
    final idx = list.indexWhere((n) => n.id == item.id);
    if (idx >= 0) {
      list[idx] = item;
    } else {
      list.insert(0, item);
    }
  }

  Future<void> refreshFromApi() async {
    if (!isLoggedIn || ApiConfig.useMockData) return;
    final integrations = await _api.fetchIntegrations();
    _connectedApps
      ..clear()
      ..addAll(integrations);
    if (_selectedAppId == null && _connectedApps.isNotEmpty) {
      _selectedAppId = _connectedApps.first.id;
    }
    for (final app in _connectedApps) {
      await _loadNotifications(app.id);
    }
    _history = await _api.fetchHistory();
    notifyListeners();
  }

  Future<void> _loadNotifications(String slug) async {
    _notificationsByApp[slug] = await _api.fetchNotifications(slug);
  }

  Future<void> _restoreSession() async {
    if (ApiConfig.useMockData) return;
    final saved = await _storage.read();
    if (saved == null) return;
    _api.setAccessToken(saved.access);
    _session = UserSession(userToken: saved.user, displayName: 'User');
    try {
      await refreshFromApi();
      await _push.registerDevice();
      await _processPendingPush();
      notifyListeners();
    } catch (_) {
      await logout();
    }
  }

  void selectApp(String appId) {
    _selectedAppId = appId;
    notifyListeners();
  }

  Future<void> markLinkClicked(
    String notificationId,
    String title,
    String appName,
  ) async {
    if (!ApiConfig.useMockData) {
      try {
        await _api.markLinkClicked(notificationId);
        await refreshFromApi();
        return;
      } catch (_) {}
    }

    final existing = _history.indexWhere(
      (h) => h.notificationId == notificationId,
    );
    if (existing >= 0) {
      _history[existing] = _history[existing].copyWith(linkClicked: true);
    } else {
      _history.insert(
        0,
        SentNotification(
          id: 's-${DateTime.now().millisecondsSinceEpoch}',
          notificationId: notificationId,
          title: title,
          appName: NotiMeBranding.publicAppName(appName),
          sentAt: DateTime.now(),
          linkClicked: true,
        ),
      );
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _session = null;
    _connectedApps.clear();
    _notificationsByApp.clear();
    _selectedAppId = null;
    _api.setAccessToken(null);
    await _storage.clear();
    notifyListeners();
  }

  void _seedDefaultConnectedApps() {
    for (final app in MockData.defaultConnectedApps) {
      if (!_connectedApps.any((a) => a.id == app.id)) {
        _connectedApps.add(app);
      }
    }
  }

  ConnectedApp _appForProject(String project) {
    switch (project) {
      case 'coursify':
        return MockData.coursify;
      case 'app_one':
        return MockData.applicationOne;
      case 'app_two':
        return MockData.applicationTwo;
      case 'app_three':
        return MockData.applicationThree;
      case 'thescratchify':
      case 'scratchify':
        return MockData.scratchify;
      default:
        return MockData.scratchify;
    }
  }
}

enum LoginResult { success, accountNotFound, invalidQr, networkError }

enum ConnectAppResult {
  success,
  alreadyConnected,
  invalidQr,
  notLoggedIn,
  networkError,
}
