import '../models/connected_app.dart';
import '../models/notification_item.dart';
import '../models/sent_notification.dart';

abstract final class MockData {
  static const notimeLogo = 'assets/images/notime_logo.png';

  static const scratchify = ConnectedApp(
    id: 'scratchify',
    projectName: 'scratchify',
    displayName: 'NotiMe',
    logoUrl: notimeLogo,
  );

  static const coursify = ConnectedApp(
    id: 'coursify',
    projectName: 'coursify',
    displayName: 'NotiMe',
    logoUrl: notimeLogo,
  );

  static const applicationOne = ConnectedApp(
    id: 'app_one',
    projectName: 'app_one',
    displayName: 'NotiMe',
    logoUrl: notimeLogo,
  );

  static const applicationTwo = ConnectedApp(
    id: 'app_two',
    projectName: 'app_two',
    displayName: 'NotiMe',
    logoUrl: notimeLogo,
  );

  static const applicationThree = ConnectedApp(
    id: 'app_three',
    projectName: 'app_three',
    displayName: 'NotiMe',
    logoUrl: notimeLogo,
  );

  static const List<ConnectedApp> defaultConnectedApps = [
    scratchify,
    applicationOne,
    applicationTwo,
    applicationThree,
  ];

  static ConnectedApp? appById(String appId) {
    for (final app in defaultConnectedApps) {
      if (app.id == appId) return app;
    }
    if (appId == coursify.id) return coursify;
    return null;
  }

  static const _lorem =
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit em ipsum dolor sit amet.';

  static const _sf1 = 'assets/images/notification_1.png';
  static const _sf2 = 'assets/images/notification_2.png';
  static const _sf3 = 'assets/images/notification_3.png';
  static const _sf4 = 'assets/images/notification_4.png';

  static List<NotificationItem> notificationsForApp(String appId) {
    return switch (appId) {
      'scratchify' => _scratchifyNotifications(),
      'app_one' => _applicationOneNotifications(),
      'app_two' => _applicationTwoNotifications(),
      'app_three' => _applicationThreeNotifications(),
      _ => [],
    };
  }

  static List<NotificationItem> _scratchifyNotifications() {
    final now = DateTime.now();
    const appId = 'scratchify';
    return [
      NotificationItem(
        id: 'sf-n1',
        appId: appId,
        title: 'Notification Name',
        body: _lorem,
        imageUrl: _sf1,
        externalUrl: 'https://example.com/notification',
        expiresAt: now.add(const Duration(hours: 20)),
      ),
      NotificationItem(
        id: 'sf-n2',
        appId: appId,
        title: 'Notification Name',
        body: _lorem,
        imageUrl: _sf2,
        externalUrl: 'https://example.com/notification',
        expiresAt: now.add(const Duration(days: 2)),
      ),
      NotificationItem(
        id: 'sf-n3',
        appId: appId,
        title: 'Notification Name',
        body: _lorem,
        imageUrl: _sf3,
        externalUrl: 'https://example.com/notification',
        expiresAt: now.add(const Duration(days: 1)),
      ),
      NotificationItem(
        id: 'sf-n4',
        appId: appId,
        title: 'Notification Name (Expired)',
        body: _lorem,
        imageUrl: _sf4,
        externalUrl: 'https://example.com/notification',
        expiresAt: now.subtract(const Duration(hours: 2)),
      ),
    ];
  }

  static List<NotificationItem> _applicationOneNotifications() {
    final now = DateTime.now();
    const appId = 'app_one';
    const name = 'Application One';
    return [
      _item(
        id: 'a1-n1',
        appId: appId,
        title: '$name — Daily reward',
        imageUrl:
            'https://images.unsplash.com/photo-1552820728-8b83bb6b773f?w=640&h=360&fit=crop',
        expiresAt: now.add(const Duration(hours: 18)),
      ),
      _item(
        id: 'a1-n2',
        appId: appId,
        title: '$name — New offer',
        imageUrl:
            'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=640&h=360&fit=crop',
        expiresAt: now.add(const Duration(days: 3)),
      ),
      _item(
        id: 'a1-n3',
        appId: appId,
        title: '$name — Weekend bonus',
        imageUrl:
            'https://images.unsplash.com/photo-1493711662062-fa541f7f76f6?w=640&h=360&fit=crop',
        expiresAt: now.add(const Duration(days: 1)),
      ),
      _item(
        id: 'a1-n4',
        appId: appId,
        title: '$name — Offer (Expired)',
        imageUrl:
            'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=640&h=360&fit=crop',
        expiresAt: now.subtract(const Duration(hours: 4)),
      ),
    ];
  }

  static List<NotificationItem> _applicationTwoNotifications() {
    final now = DateTime.now();
    const appId = 'app_two';
    const name = 'Application Two';
    return [
      _item(
        id: 'a2-n1',
        appId: appId,
        title: '$name — Shop deal',
        imageUrl:
            'https://images.unsplash.com/photo-1607082349566-187342175e2f?w=640&h=360&fit=crop',
        expiresAt: now.add(const Duration(hours: 12)),
      ),
      _item(
        id: 'a2-n2',
        appId: appId,
        title: '$name — Flash sale',
        imageUrl:
            'https://images.unsplash.com/photo-1472851294608-062f824d29cc?w=640&h=360&fit=crop',
        expiresAt: now.add(const Duration(days: 2)),
      ),
      _item(
        id: 'a2-n3',
        appId: appId,
        title: '$name — Member perk',
        imageUrl:
            'https://images.unsplash.com/photo-1563013544945-6f4d07b0f6b9?w=640&h=360&fit=crop',
        expiresAt: now.add(const Duration(days: 4)),
      ),
      _item(
        id: 'a2-n4',
        appId: appId,
        title: '$name — Deal (Expired)',
        imageUrl:
            'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=640&h=360&fit=crop',
        expiresAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  static List<NotificationItem> _applicationThreeNotifications() {
    final now = DateTime.now();
    const appId = 'app_three';
    const name = 'Application Three';
    return [
      _item(
        id: 'a3-n1',
        appId: appId,
        title: '$name — Travel alert',
        imageUrl:
            'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=640&h=360&fit=crop',
        expiresAt: now.add(const Duration(hours: 24)),
      ),
      _item(
        id: 'a3-n2',
        appId: appId,
        title: '$name — City guide',
        imageUrl:
            'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=640&h=360&fit=crop',
        expiresAt: now.add(const Duration(days: 5)),
      ),
      _item(
        id: 'a3-n3',
        appId: appId,
        title: '$name — Event invite',
        imageUrl:
            'https://images.unsplash.com/photo-1501785881915-7d02c9a221b8?w=640&h=360&fit=crop',
        expiresAt: now.add(const Duration(days: 2)),
      ),
      _item(
        id: 'a3-n4',
        appId: appId,
        title: '$name — Alert (Expired)',
        imageUrl:
            'https://images.unsplash.com/photo-1502920917128-1aa500764cbd?w=640&h=360&fit=crop',
        expiresAt: now.subtract(const Duration(hours: 6)),
      ),
    ];
  }

  static NotificationItem _item({
    required String id,
    required String appId,
    required String title,
    required String imageUrl,
    DateTime? expiresAt,
  }) {
    return NotificationItem(
      id: id,
      appId: appId,
      title: title,
      body: _lorem,
      imageUrl: imageUrl,
      externalUrl: 'https://heynotime.com/',
      expiresAt: expiresAt,
    );
  }

  static final List<SentNotification> initialHistory = [
    SentNotification(
      id: 's1',
      notificationId: 'sf-n1',
      title: 'Notification Name',
      appName: 'NotiMe',
      sentAt: DateTime.now().subtract(const Duration(hours: 3)),
      linkClicked: true,
    ),
    SentNotification(
      id: 's2',
      notificationId: 'sf-n2',
      title: 'Notification Name',
      appName: 'NotiMe',
      sentAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
    SentNotification(
      id: 's3',
      notificationId: 'sf-n4',
      title: 'Notification Name (Expired)',
      appName: 'NotiMe',
      sentAt: DateTime.now().subtract(const Duration(days: 3)),
      linkClicked: true,
    ),
  ];
}
