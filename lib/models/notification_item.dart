class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.appId,
    required this.title,
    required this.body,
    required this.imageUrl,
    required this.externalUrl,
    this.expiresAt,
    this.isRead = false,
  });

  final String id;
  final String appId;
  final String title;
  final String body;
  final String imageUrl;
  final String externalUrl;
  final DateTime? expiresAt;
  final bool isRead;

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}
