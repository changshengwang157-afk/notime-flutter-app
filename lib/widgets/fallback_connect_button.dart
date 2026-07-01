import 'package:flutter/material.dart';

import '../api/notime_api_client.dart';
import '../config/api_config.dart';
import '../core/theme/notime_theme.dart';
import 'notification_image.dart';

/// Logo button for fallback connect when QR pairing fails.
class FallbackConnectButton extends StatefulWidget {
  const FallbackConnectButton({
    super.key,
    required this.slug,
    required this.onPressed,
    this.compact = false,
  });

  final String slug;
  final VoidCallback onPressed;
  final bool compact;

  @override
  State<FallbackConnectButton> createState() => _FallbackConnectButtonState();
}

class _FallbackConnectButtonState extends State<FallbackConnectButton> {
  ConnectInfo? _info;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (!ApiConfig.useMockData) {
      _loadInfo();
    } else {
      _loading = false;
    }
  }

  Future<void> _loadInfo() async {
    try {
      final info = await NotiMeApiClient().fetchConnectInfo(widget.slug);
      if (!mounted) return;
      setState(() {
        _info = info;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final info = _info;
    if (info != null && !info.allowFallbackConnect) {
      return const SizedBox.shrink();
    }

    final label = info?.fallbackConnectLabel ??
        'Connect with ${info?.displayName ?? 'your app'}';
    final logoUrl = info?.logoUrl ?? '';

    if (widget.compact) {
      return TextButton.icon(
        onPressed: widget.onPressed,
        icon: _LogoThumb(logoUrl: logoUrl),
        label: Text(label),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          'Having trouble scanning?',
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
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                border: Border.all(color: NotiMeColors.border),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  if (logoUrl.isNotEmpty)
                    NotificationImage(
                      path: logoUrl,
                      height: 56,
                      width: 160,
                      fit: BoxFit.contain,
                    )
                  else
                    const Icon(
                      Icons.apps_rounded,
                      size: 48,
                      color: NotiMeColors.textPrimary,
                    ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: NotiMeColors.textPrimary,
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

class _LogoThumb extends StatelessWidget {
  const _LogoThumb({required this.logoUrl});

  final String logoUrl;

  @override
  Widget build(BuildContext context) {
    if (logoUrl.isEmpty) {
      return const Icon(Icons.link, size: 20);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: NotificationImage(path: logoUrl, height: 24, width: 24),
    );
  }
}
