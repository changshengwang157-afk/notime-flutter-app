import 'package:flutter/material.dart';

import '../core/theme/notime_theme.dart';

/// Help information sheet.
void showHelpSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (_, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: const [
          Text(
            'Help',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text(
            'Scan a QR code on the login screen to connect your account. '
            'After login, use the menu in the top right to add more apps, '
            'switch applications, or log out.',
            style: TextStyle(color: NotiMeColors.textSecondary, height: 1.45),
          ),
          SizedBox(height: 16),
          Text(
            'Tap a notification to view details. Expired notifications appear '
            'grayed out and cannot be opened.',
            style: TextStyle(color: NotiMeColors.textSecondary, height: 1.45),
          ),
        ],
      ),
    ),
  );
}
