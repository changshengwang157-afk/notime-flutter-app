import 'package:flutter/foundation.dart';

import '../data/mock_data.dart';
import '../models/connected_app.dart';
import '../models/notification_item.dart';
import '../models/sent_notification.dart';
import '../models/user_session.dart';

/// In-memory app state for the UI prototype (no API / Firebase).
class AppState extends ChangeNotifier {
  UserSession? _session;
  final List<ConnectedApp> _connectedApps = [];
  final List<SentNotification> _history = [...MockData.initialHistory];
  String? _selectedAppId;

  UserSession? get session => _session;
  bool get isLoggedIn => _session != null;
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

  List<NotificationItem> notificationsForSelectedApp() {
    final app = selectedApp;
    if (app == null) return [];
    return MockData.notificationsForApp(app.id);
  }

  NotificationItem? notificationById(String id) {
    for (final app in _connectedApps) {
      for (final n in MockData.notificationsForApp(app.id)) {
        if (n.id == id) return n;
      }
    }
    return null;
  }

  /// Simulates QR login: `notime://login?project=scratchify&user=TOKEN`
  LoginResult loginFromQrPayload(String raw) {
    final uri = _parseQr(raw);
    if (uri == null) {
      return LoginResult.invalidQr;
    }

    final project = uri.queryParameters['project']?.trim().toLowerCase();
    final userToken = uri.queryParameters['user']?.trim();

    if (project == null || userToken == null || userToken.isEmpty) {
      return LoginResult.invalidQr;
    }

    if (userToken == 'invalid' || userToken == 'not-found') {
      return LoginResult.accountNotFound;
    }

    _session = UserSession(
      userToken: userToken,
      displayName: 'User',
    );

    final app = _appForProject(project);
    _seedDefaultConnectedApps();
    if (!_connectedApps.any((a) => a.id == app.id)) {
      _connectedApps.add(app);
    }
    _selectedAppId = app.id;
    notifyListeners();
    return LoginResult.success;
  }

  /// Add another connected app (Option 1).
  ConnectAppResult connectAppFromQr(String raw) {
    if (!isLoggedIn) return ConnectAppResult.notLoggedIn;

    final uri = _parseQr(raw);
    if (uri == null) return ConnectAppResult.invalidQr;

    final project = uri.queryParameters['project']?.trim().toLowerCase();
    if (project == null) return ConnectAppResult.invalidQr;

    final app = _appForProject(project);
    if (_connectedApps.any((a) => a.id == app.id)) {
      return ConnectAppResult.alreadyConnected;
    }
    _connectedApps.add(app);
    _selectedAppId = app.id;
    notifyListeners();
    return ConnectAppResult.success;
  }

  void selectApp(String appId) {
    _selectedAppId = appId;
    notifyListeners();
  }

  void markLinkClicked(String notificationId, String title, String appName) {
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

  void logout() {
    _session = null;
    _connectedApps.clear();
    _selectedAppId = null;
    notifyListeners();
  }

  Uri? _parseQr(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    try {
      if (trimmed.startsWith('http')) {
        return Uri.parse(trimmed);
      }
      if (trimmed.startsWith('notime://')) {
        return Uri.parse(trimmed);
      }
      // Plain JSON-style demo payloads from buttons
      if (trimmed.contains('project=')) {
        return Uri.parse('notime://login?$trimmed');
      }
    } catch (_) {
      return null;
    }
    return null;
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
      case 'scratchify':
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
