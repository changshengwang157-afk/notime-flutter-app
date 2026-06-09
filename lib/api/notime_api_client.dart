import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/connected_app.dart';
import '../models/notification_item.dart';
import '../models/sent_notification.dart';

class NotiMeApiException implements Exception {
  NotiMeApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class PairResult {
  const PairResult({
    required this.accessToken,
    required this.userToken,
    required this.integration,
    this.message,
  });

  final String accessToken;
  final String userToken;
  final ConnectedApp integration;
  final String? message;
}

class NotiMeApiClient {
  NotiMeApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? _accessToken;

  void setAccessToken(String? token) => _accessToken = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  Future<PairResult> pair({required String slug, required String token}) async {
    final res = await _client.post(
      Uri.parse('${ApiConfig.apiV1}/pair/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'slug': slug, 'token': token}),
    );
    if (res.statusCode != 200) {
      throw NotiMeApiException(_errorBody(res), statusCode: res.statusCode);
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final integ = data['integration'] as Map<String, dynamic>;
    return PairResult(
      accessToken: data['access_token'] as String,
      userToken: data['user_token'] as String,
      message: data['message'] as String?,
      integration: ConnectedApp(
        id: integ['slug'] as String,
        projectName: integ['slug'] as String,
        displayName: integ['display_name'] as String,
        logoUrl: (integ['logo_url'] as String?) ?? '',
      ),
    );
  }

  Future<void> registerDevice({
    required String fcmToken,
    String platform = 'android',
  }) async {
    final res = await _client.post(
      Uri.parse('${ApiConfig.apiV1}/devices/'),
      headers: _headers,
      body: jsonEncode({'fcm_token': fcmToken, 'platform': platform}),
    );
    if (res.statusCode != 200) {
      throw NotiMeApiException(_errorBody(res), statusCode: res.statusCode);
    }
  }

  Future<List<ConnectedApp>> fetchIntegrations() async {
    final res = await _client.get(
      Uri.parse('${ApiConfig.apiV1}/integrations/'),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      throw NotiMeApiException(_errorBody(res), statusCode: res.statusCode);
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list = data['integrations'] as List<dynamic>;
    return list
        .map(
          (e) => ConnectedApp(
            id: e['slug'] as String,
            projectName: e['slug'] as String,
            displayName: e['display_name'] as String,
            logoUrl: (e['logo_url'] as String?) ?? '',
          ),
        )
        .toList();
  }

  Future<List<NotificationItem>> fetchNotifications(String slug) async {
    final res = await _client.get(
      Uri.parse('${ApiConfig.apiV1}/integrations/$slug/notifications/'),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      throw NotiMeApiException(_errorBody(res), statusCode: res.statusCode);
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list = data['notifications'] as List<dynamic>;
    return list
        .map((e) => _notificationFromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SentNotification>> fetchHistory() async {
    final res = await _client.get(
      Uri.parse('${ApiConfig.apiV1}/history/'),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      throw NotiMeApiException(_errorBody(res), statusCode: res.statusCode);
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list = data['history'] as List<dynamic>;
    return list.map((e) {
      return SentNotification(
        id: e['id'] as String,
        notificationId: e['notification_id'] as String,
        title: e['title'] as String,
        appName: e['app_name'] as String,
        sentAt: DateTime.parse(e['sent_at'] as String),
        linkClicked: e['link_clicked'] as bool? ?? false,
      );
    }).toList();
  }

  Future<NotificationItem> fetchNotificationDetail(String deliveryId) async {
    final res = await _client.get(
      Uri.parse('${ApiConfig.apiV1}/notifications/$deliveryId/'),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      throw NotiMeApiException(_errorBody(res), statusCode: res.statusCode);
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return _notificationFromJson(data);
  }

  Future<void> markLinkClicked(String deliveryId) async {
    await _client.post(
      Uri.parse('${ApiConfig.apiV1}/notifications/$deliveryId/'),
      headers: _headers,
    );
  }

  NotificationItem _notificationFromJson(Map<String, dynamic> e) {
    final availableTo = e['available_to'] as String?;
    return NotificationItem(
      id: e['id'] as String,
      appId: e['integration_slug'] as String,
      title: e['title'] as String,
      body: (e['body'] as String?) ?? '',
      imageUrl: (e['image_url'] as String?) ?? '',
      externalUrl: e['external_url'] as String,
      expiresAt:
          availableTo != null ? DateTime.tryParse(availableTo) : null,
    );
  }

  String _errorBody(http.Response res) {
    try {
      final m = jsonDecode(res.body) as Map<String, dynamic>;
      return (m['detail'] as String?) ?? res.body;
    } catch (_) {
      return 'Request failed (${res.statusCode})';
    }
  }
}

/// Parses `https://heynotime.com/{slug}/{token}` and legacy demo formats.
({String slug, String token})? parsePairingPayload(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  try {
    if (trimmed.startsWith('http')) {
      final uri = Uri.parse(trimmed);
      final segments =
          uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.length >= 2) {
        return (slug: segments[0], token: segments[1]);
      }
    }
    if (trimmed.startsWith('notime://')) {
      final uri = Uri.parse(trimmed);
      final project = uri.queryParameters['project'];
      final user = uri.queryParameters['user'];
      if (project != null && user != null) {
        return (slug: project, token: user);
      }
    }
    if (trimmed.contains('project=')) {
      final uri = Uri.parse('notime://login?$trimmed');
      final project = uri.queryParameters['project'];
      final user = uri.queryParameters['user'];
      if (project != null && user != null) {
        return (slug: project, token: user);
      }
    }
  } catch (_) {
    return null;
  }
  return null;
}
