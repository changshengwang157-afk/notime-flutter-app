import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/notime_theme.dart';
import '../widgets/notime_app_bar_title.dart';
import '../widgets/notime_scaffold.dart';

class AccountNotFoundScreen extends StatelessWidget {
  const AccountNotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return NotiMePage(
      appBar: AppBar(
        title: const NotiMeAppBarTitle(),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 72,
              color: NotiMeColors.danger.withValues(alpha: 0.85),
            ),
            const SizedBox(height: 24),
            const Text(
              'Account not found.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: NotiMeColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please contact the app administrator.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: NotiMeColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Scan QR again'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
