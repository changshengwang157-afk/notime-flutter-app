class SentNotification {
  const SentNotification({
    required this.id,
    required this.notificationId,
    required this.title,
    required this.appName,
    required this.sentAt,
    this.linkClicked = false,
  });

  final String id;
  final String notificationId;
  final String title;
  final String appName;
  final DateTime sentAt;
  final bool linkClicked;

  SentNotification copyWith({bool? linkClicked}) {
    return SentNotification(
      id: id,
      notificationId: notificationId,
      title: title,
      appName: appName,
      sentAt: sentAt,
      linkClicked: linkClicked ?? this.linkClicked,
    );
  }
}
