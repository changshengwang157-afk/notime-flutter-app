import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';

/// Normalizes FCM / local-notification payload keys across Android and iOS.
Map<String, String> extractPushPayload(Map<String, dynamic> raw) {
  final flat = <String, String>{};

  void absorb(dynamic value, [String? prefix]) {
    if (value is Map) {
      value.forEach((key, nested) {
        final name = prefix == null ? '$key' : '$prefix.$key';
        absorb(nested, name);
      });
      return;
    }
    if (value == null) return;
    final key = prefix ?? '';
    if (key.isEmpty) return;
    flat[key] = '$value';
  }

  absorb(raw);

  String? pick(List<String> keys) {
    for (final key in keys) {
      final direct = flat[key]?.trim();
      if (direct != null && direct.isNotEmpty) return direct;
    }
    // Case-insensitive fallback (some iOS builds vary key casing).
    for (final entry in flat.entries) {
      final lower = entry.key.toLowerCase();
      for (final key in keys) {
        if (lower == key.toLowerCase()) {
          final value = entry.value.trim();
          if (value.isNotEmpty) return value;
        }
      }
    }
    return null;
  }

  final deliveryId = pick([
    'delivery_id',
    'deliveryId',
    'delivery-id',
    'gcm.notification.delivery_id',
    'google.c.a.c_l',
  ]);
  final slug = pick([
    'integration_slug',
    'integrationSlug',
    'integration-slug',
    'gcm.notification.integration_slug',
  ]);

  final normalized = <String, String>{...flat};
  if (deliveryId != null) normalized['delivery_id'] = deliveryId;
  if (slug != null) normalized['integration_slug'] = slug;
  return normalized;
}

Map<String, String> extractPushPayloadFromMessage(RemoteMessage message) {
  final merged = <String, dynamic>{...message.data};

  // iOS may nest custom fields under a JSON "data" string.
  final nested = message.data['data'];
  if (nested is String && nested.trim().startsWith('{')) {
    try {
      final decoded = jsonDecode(nested);
      if (decoded is Map) {
        merged.addAll(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
  }

  return extractPushPayload(merged);
}
