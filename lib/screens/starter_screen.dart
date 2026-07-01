import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../api/notime_api_client.dart';
import '../config/api_config.dart';
import '../core/theme/notime_theme.dart';
import '../services/app_state.dart';
import '../services/camera_permission.dart';
import '../widgets/fallback_connect_button.dart';
import '../widgets/notime_app_bar_title.dart';
import '../widgets/notime_scaffold.dart';
import '../widgets/paste_pairing_url_dialog.dart';
import '../widgets/qr_scanner_view.dart';

/// QR login — matches https://heynotime.com/mobile-preview/starter-tab/
class StarterScreen extends StatefulWidget {
  const StarterScreen({super.key});

  @override
  State<StarterScreen> createState() => _StarterScreenState();
}

class _StarterScreenState extends State<StarterScreen> {
  String? _lastScan;
  String? _lastAttemptedSlug;

  String get _fallbackSlug =>
      _lastAttemptedSlug ?? ApiConfig.fallbackConnectSlug;

  Future<void> _openScanner() async {
    final granted = await ensureCameraPermission();
    if (!mounted) return;
    if (!granted) {
      final denied = await isCameraPermanentlyDenied();
      _showSnack(cameraPermissionMessage(denied));
      return;
    }

    final payload = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _QrScannerPage(),
      ),
    );
    if (payload != null && mounted) {
      await _handlePayload(payload);
    }
  }

  Future<void> _openPasteUrlDialog() async {
    final payload = await showDialog<String>(
      context: context,
      builder: (_) => const PastePairingUrlDialog(),
    );
    if (payload != null && payload.isNotEmpty && mounted) {
      await _handlePayload(payload);
    }
  }

  Future<void> _handlePayload(String payload) async {
    if (_lastScan == payload) return;
    _lastScan = payload;

    final parsed = parsePairingPayload(payload);
    if (parsed != null) {
      _lastAttemptedSlug = parsed.slug;
    }

    final state = context.read<AppState>();
    final result = await state.loginFromQrPayload(payload);

    if (!mounted) return;
    await _handleLoginResult(
      result,
      slug: context.read<AppState>().selectedApp?.id ?? _fallbackSlug,
    );
  }

  Future<void> _handleFallbackConnect() async {
    final state = context.read<AppState>();
    final result = await state.loginFallbackConnect(_fallbackSlug);
    if (!mounted) return;
    await _handleLoginResult(
      result,
      slug: state.selectedApp?.id ?? _fallbackSlug,
    );
  }

  Future<void> _handleLoginResult(LoginResult result, {required String slug}) async {
    final state = context.read<AppState>();

    switch (result) {
      case LoginResult.success:
        final message = state.lastSuccessMessage;
        if (message != null && message.isNotEmpty) {
          _showSnack(message);
          state.clearLastSuccessMessage();
        }
        if (!mounted) return;
        context.go('/home/$slug');
      case LoginResult.accountNotFound:
        context.push('/account-not-found');
      case LoginResult.invalidQr:
        await _showInvalidQrDialog();
        Future.delayed(const Duration(seconds: 2), () => _lastScan = null);
      case LoginResult.networkError:
        _showSnack(state.error ??
            'Could not reach the server. Check your connection and try again.');
        Future.delayed(const Duration(seconds: 2), () => _lastScan = null);
    }
  }

  Future<void> _showInvalidQrDialog() async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Couldn't scan the QR code"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'You can still connect and receive notifications without scanning.',
            ),
            const SizedBox(height: 16),
            FallbackConnectButton(
              slug: _fallbackSlug,
              compact: true,
              onPressed: () => Navigator.pop(context, 'fallback'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'retry'),
            child: const Text('Scan again'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'paste'),
            child: const Text('Paste URL'),
          ),
        ],
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'fallback') {
      await _handleFallbackConnect();
    } else if (action == 'paste') {
      await _openPasteUrlDialog();
    } else if (action == 'retry') {
      await _openScanner();
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return NotiMePage(
      appBar: AppBar(
        title: const NotiMeAppBarTitle(),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Receive Notifications From Your Favorite Apps',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: NotiMeColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _StepRow(
                      number: '1',
                      text:
                          'Scan the QR code to log in and connect our app with the notification system.',
                    ),
                    const SizedBox(height: 8),
                    const _StepRow(
                      number: '2',
                      text:
                          'Done! Now you will receive your favorite notifications in NotiMe.',
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _openScanner,
                        icon: const Icon(Icons.qr_code_scanner, size: 22),
                        label: const Text(
                          'Scan QR Code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: NotiMeColors.textPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _openPasteUrlDialog,
                      icon: const Icon(Icons.link, size: 20),
                      label: const Text('Paste pairing URL'),
                      style: TextButton.styleFrom(
                        foregroundColor: NotiMeColors.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    FallbackConnectButton(
                      slug: _fallbackSlug,
                      onPressed: _handleFallbackConnect,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Full-screen camera — opened only after tapping "Scan QR Code".
class _QrScannerPage extends StatelessWidget {
  const _QrScannerPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan QR Code'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: 'Paste pairing URL',
            onPressed: () async {
              final navigator = Navigator.of(context);
              final payload = await showDialog<String>(
                context: context,
                builder: (_) => const PastePairingUrlDialog(),
              );
              if (payload != null && payload.isNotEmpty) {
                navigator.pop(payload);
              }
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          QrScannerView(
            onScanned: (payload) {
              if (!context.mounted) return;
              Navigator.of(context).pop(payload);
            },
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: NotiMeColors.primary, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: NotiMeColors.primary,
          child: Text(
            number,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: NotiMeColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
