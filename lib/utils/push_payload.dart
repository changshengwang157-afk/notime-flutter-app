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
      final value = flat[key]?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  final deliveryId = pick([
    'delivery_id',
    'deliveryId',
    'gcm.notification.delivery_id',
    'google.c.a.c_l',
  ]);
  final slug = pick([
    'integration_slug',
    'integrationSlug',
    'gcm.notification.integration_slug',
  ]);

  final normalized = <String, String>{...flat};
  if (deliveryId != null) normalized['delivery_id'] = deliveryId;
  if (slug != null) normalized['integration_slug'] = slug;
  return normalized;
}

Map<String, String> extractPushPayloadFromMessage(RemoteMessage message) {
  return extractPushPayload(Map<String, dynamic>.from(message.data));
}
