import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import '../api/notime_api_client.dart';

/// Listens for pairing URLs and fallback connect links.
class DeepLinkService {
  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  void listen({
    required void Function(String payload) onPairingUrl,
    required void Function(String slug) onConnectSlug,
  }) {
    _sub?.cancel();
    _sub = _appLinks.uriLinkStream.listen(
      (uri) => _dispatch(uri.toString(), onPairingUrl, onConnectSlug),
      onError: (e) => debugPrint('Deep link error: $e'),
    );

    _appLinks.getInitialLink().then((uri) {
      if (uri == null) return;
      _dispatch(uri.toString(), onPairingUrl, onConnectSlug);
    });
  }

  void _dispatch(
    String payload,
    void Function(String payload) onPairingUrl,
    void Function(String slug) onConnectSlug,
  ) {
    final connectSlug = parseConnectSlug(payload);
    if (connectSlug != null) {
      onConnectSlug(connectSlug);
      return;
    }
    if (parsePairingPayload(payload) != null) {
      onPairingUrl(payload);
    }
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
