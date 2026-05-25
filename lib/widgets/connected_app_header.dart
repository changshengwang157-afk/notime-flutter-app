import 'package:flutter/material.dart';

import '../core/theme/notime_theme.dart';
import '../data/mock_data.dart';
import '../models/connected_app.dart';
import 'notification_image.dart';

/// Header above the notification list — app logo + subtitle (no duplicate app title).
class ConnectedAppHeader extends StatelessWidget {
  const ConnectedAppHeader({super.key, required this.app});

  final ConnectedApp app;

  bool get _isWideBrandLogo =>
      app.logoUrl.startsWith('assets/') || app.id == 'scratchify';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          if (_isWideBrandLogo)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Image.asset(
                app.logoUrl,
                height: 56,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Image.asset(
                  MockData.scratchifyLogo,
                  height: 56,
                  fit: BoxFit.contain,
                ),
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: NotificationImage(
                path: app.logoUrl,
                height: 72,
                width: 72,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Notifications from ${app.displayName}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: NotiMeColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
