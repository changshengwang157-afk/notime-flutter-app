import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/notime_theme.dart';
import '../models/notification_item.dart';
import 'notification_image.dart';

class NotificationListTile extends StatelessWidget {
  const NotificationListTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final expired = item.isExpired;
    final dateFormat = DateFormat('MMM d, HH:mm');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: expired ? NotiMeColors.expiredBg : NotiMeColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: expired ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: expired ? NotiMeColors.expired : NotiMeColors.border,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _PreviewImage(path: item.imageUrl, dimmed: expired),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: expired
                              ? NotiMeColors.expired
                              : NotiMeColors.textPrimary,
                          decoration:
                              expired ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        expired && item.expiresAt != null
                            ? 'Expired · ${dateFormat.format(item.expiresAt!)}'
                            : item.expiresAt != null
                                ? 'Ends ${dateFormat.format(item.expiresAt!)}'
                                : item.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: expired
                              ? NotiMeColors.expired
                              : NotiMeColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: expired ? NotiMeColors.expired : NotiMeColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewImage extends StatelessWidget {
  const _PreviewImage({required this.path, required this.dimmed});

  final String path;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColorFiltered(
        colorFilter: dimmed
            ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
            : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
        child: NotificationImage(
          path: path,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
