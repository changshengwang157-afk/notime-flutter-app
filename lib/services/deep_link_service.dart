import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import '../api/notime_api_client.dart';

/// Listens for https://heynotime.com/{slug}/{token}/ universal / app links.
class DeepLinkService {
  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  void listen(void Function(String payload) onPairingUrl) {
    _sub?.cancel();
    _sub = _appLinks.uriLinkStream.listen(
      (uri) {
        final payload = uri.toString();
        if (parsePairingPayload(payload) != null) {
          onPairingUrl(payload);
        }
      },
      onError: (e) => debugPrint('Deep link error: $e'),
    );

    _appLinks.getInitialLink().then((uri) {
      if (uri == null) return;
      final payload = uri.toString();
      if (parsePairingPayload(payload) != null) {
        onPairingUrl(payload);
      }
    });
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
