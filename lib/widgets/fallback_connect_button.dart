import 'package:flutter/material.dart';

import '../core/theme/notime_theme.dart';

/// Generic fallback connect — NotiMe branding only (no partner name/logo).
class FallbackConnectButton extends StatelessWidget {
  const FallbackConnectButton({
    super.key,
    required this.onPressed,
    this.compact = false,
  });

  static const String label = 'Continue without QR';
  static const String hint = 'Having trouble scanning?';

  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.notifications_active_outlined, size: 20),
        label: const Text(label),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          hint,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: NotiMeColors.textSecondary.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                border: Border.all(color: NotiMeColors.border),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    size: 48,
                    color: NotiMeColors.textPrimary,
                  ),
                  SizedBox(height: 10),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: NotiMeColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Connect and receive reminders & alerts',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: NotiMeColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
