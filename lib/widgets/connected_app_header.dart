import 'package:flutter/material.dart';

import '../core/notime_branding.dart';
import '../core/theme/notime_theme.dart';

/// NotiMe header above the notification list — no partner logos or names.
class ConnectedAppHeader extends StatelessWidget {
  const ConnectedAppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              NotiMeBranding.logoAsset,
              height: 56,
              width: 56,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            NotiMeBranding.notificationsHeader,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: NotiMeColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
