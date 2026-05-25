import 'package:flutter/material.dart';

import '../core/theme/notime_theme.dart';

/// Logo + "NotiMe" for the app bar (matches heynotime mobile preview).
class NotiMeAppBarTitle extends StatelessWidget {
  const NotiMeAppBarTitle({super.key});

  static const _logoAsset = 'assets/images/notime_logo.png';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            _logoAsset,
            width: 32,
            height: 32,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'NotiMe',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: NotiMeColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
