import '../models/connected_app.dart';
import '../models/sent_notification.dart';

/// User-facing copy and labels — NotiMe only (no partner / integration names).
abstract final class NotiMeBranding {
  static const logoAsset = 'assets/images/notime_logo.png';

  static const notificationsHeader = 'Your notifications & reminders';
  static const historySource = 'NotiMe';
  static const connectSuccess =
      'You\'re connected. Notifications and reminders are ready.';
  static const singleAppMenuLabel = 'Notifications';
  static const pushChannelDescription =
      'Notifications and reminders with custom sound';

  /// Menu label when the user has more than one connected integration.
  static String menuLabelForApp({required int index, required int total}) {
    if (total <= 1) return singleAppMenuLabel;
    return 'Notifications ${index + 1}';
  }

  /// Never show API integration names in the UI.
  static String publicAppName(String? _) => historySource;

  /// Strip partner branding from API integrations (slug/id unchanged for routing).
  static ConnectedApp sanitizeIntegration(ConnectedApp app) => ConnectedApp(
        id: app.id,
        projectName: app.projectName,
        displayName: historySource,
        logoUrl: logoAsset,
      );

  static SentNotification sanitizeHistory(SentNotification item) =>
      SentNotification(
        id: item.id,
        notificationId: item.notificationId,
        title: item.title,
        appName: historySource,
        sentAt: item.sentAt,
        linkClicked: item.linkClicked,
      );
}
