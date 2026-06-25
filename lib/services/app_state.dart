import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/notime_api_client.dart';
import '../config/api_config.dart';
import '../data/mock_data.dart';
import '../models/connected_app.dart';
import '../models/notification_item.dart';
import '../models/sent_notification.dart';
import '../models/user_session.dart';
import '../utils/external_link.dart';
import 'push_service.dart';
import 'session_storage.dart';
import 'deep_link_service.dart';

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
  final NotiMeApiClient _api = NotiMeApiClient();
  late final PushService _push = PushService(api: _api);
  final DeepLinkService _deepLinks = DeepLinkService();

  UserSession? _session;
  final List<ConnectedApp> _connectedApps = [];
  final Map<String, List<NotificationItem>> _notificationsByApp = {};
  List<SentNotification> _history = [...MockData.initialHistory];
  String? _selectedAppId;
  bool _loading = false;
  String? _error;

  UserSession? get session => _session;
  bool get isLoggedIn => _session != null;
  bool get isLoading => _loading;
  String? get error => _error;
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
      await refreshFromApi();
      await _push.registerDevice();
      return LoginResult.success;
    } on NotiMeApiException catch (e) {
      _error = e.message;
      if (e.statusCode == 404 || e.statusCode == 400) {
        return LoginResult.invalidQr;
      }
      return LoginResult.invalidQr;
    } finally {
      _loading = false;
      notifyListeners();
    }
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
    }
  }

  /// Called once from [NotiMeApp] — wires FCM tap → scratch card.
  Future<void> setupPushHandlers() async {
    await _push.configure(onTap: _handlePushTap);
    await ready;
    await _push.processInitialMessage();
  }

  /// Universal / app links: https://heynotime.com/{slug}/{token}/
  void setupDeepLinks(void Function(String payload) onPayload) {
    _deepLinks.listen((payload) async {
      if (isLoggedIn) {
        onPayload(payload);
        return;
      }
      final result = await loginFromQrPayload(payload);
      if (result == LoginResult.success) {
        onPayload(payload);
      }
    });
  }

  void dispose() {
    _deepLinks.dispose();
  }

  Future<void> _handlePushTap(Map<String, String> data) async {
    if (!isLoggedIn || ApiConfig.useMockData) return;

    final deliveryId = data['delivery_id']?.trim();
    if (deliveryId == null || deliveryId.isEmpty) return;

    var item = notificationById(deliveryId);
    if (item == null) {
      try {
        item = await _api.fetchNotificationDetail(deliveryId);
        _cacheNotification(item);
        notifyListeners();
      } catch (e) {
        debugPrint('Push tap: could not load $deliveryId: $e');
        return;
      }
    }

    if (item.isExpired) return;

    final appName = connectedAppById(item.appId)?.displayName ?? 'App';
    final token = _session!.userToken;
    final uri = appendUserQuery(item.externalUrl, token);

    await markLinkClicked(item.id, item.title, appName);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
          appName: appName,
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

enum LoginResult { success, accountNotFound, invalidQr }

enum ConnectAppResult {
  success,
  alreadyConnected,
  invalidQr,
  notLoggedIn,
}
