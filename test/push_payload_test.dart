import 'package:flutter_test/flutter_test.dart';
import 'package:notime_app/utils/push_payload.dart';

void main() {
  test('extractPushPayload reads delivery_id and integration_slug', () {
    final payload = extractPushPayload({
      'delivery_id': '294',
      'integration_slug': 'thescratchify',
    });
    expect(payload['delivery_id'], '294');
    expect(payload['integration_slug'], 'thescratchify');
  });

  test('extractPushPayload is case-insensitive', () {
    final payload = extractPushPayload({
      'Delivery_Id': '100',
      'Integration_Slug': 'demo',
    });
    expect(payload['delivery_id'], '100');
    expect(payload['integration_slug'], 'demo');
  });

  test('extractPushPayload reads nested gcm keys', () {
    final payload = extractPushPayload({
      'gcm': {
        'notification': {
          'delivery_id': '55',
          'integration_slug': 'app',
        },
      },
    });
    expect(payload['delivery_id'], '55');
    expect(payload['integration_slug'], 'app');
  });
}
