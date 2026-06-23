import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../api/notime_api_client.dart';
import '../core/theme/notime_theme.dart';
import '../services/app_state.dart';
import '../services/camera_permission.dart';
import '../widgets/notime_app_bar_title.dart';
import '../widgets/notime_scaffold.dart';
import '../widgets/qr_scanner_view.dart';

/// QR login — matches https://heynotime.com/mobile-preview/starter-tab/
class StarterScreen extends StatefulWidget {
  const StarterScreen({super.key});

  @override
  State<StarterScreen> createState() => _StarterScreenState();
}

class _StarterScreenState extends State<StarterScreen> {
  String? _lastScan;

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
      builder: (_) => const _PastePairingUrlDialog(),
    );
    if (payload != null && payload.isNotEmpty && mounted) {
      await _handlePayload(payload);
    }
  }

  Future<void> _handlePayload(String payload) async {
    if (_lastScan == payload) return;
    _lastScan = payload;

    final state = context.read<AppState>();
    final result = await state.loginFromQrPayload(payload);

    if (!mounted) return;

    switch (result) {
      case LoginResult.success:
        final slug = context.read<AppState>().selectedApp?.id ?? 'thescratchify';
        context.go('/home/$slug');
      case LoginResult.accountNotFound:
        context.push('/account-not-found');
      case LoginResult.invalidQr:
        await _showInvalidQrDialog();
        Future.delayed(const Duration(seconds: 2), () => _lastScan = null);
    }
  }

  Future<void> _showInvalidQrDialog() async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invalid QR code'),
        content: const Text(
          'This QR code is not a valid NotiMe pairing link. '
          'Get a fresh link from Dashboard → My Users, or paste the URL manually.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'retry'),
            child: const Text('Scan again'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'paste'),
            child: const Text('Paste URL'),
          ),
        ],
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'paste') {
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
class _QrScannerPage extends StatefulWidget {
  const _QrScannerPage();

  @override
  State<_QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<_QrScannerPage> {
  void _onScanned(String payload) {
    Navigator.of(context).pop(payload);
  }

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
                builder: (_) => const _PastePairingUrlDialog(),
              );
              if (payload != null && payload.isNotEmpty && mounted) {
                navigator.pop(payload);
              }
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          QrScannerView(onScanned: _onScanned),
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

/// Manual pairing fallback when the camera scanner is unavailable (e.g. iOS TestFlight debug).
class _PastePairingUrlDialog extends StatefulWidget {
  const _PastePairingUrlDialog();

  @override
  State<_PastePairingUrlDialog> createState() => _PastePairingUrlDialogState();
}

class _PastePairingUrlDialogState extends State<_PastePairingUrlDialog> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pasteFromClipboard();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty && mounted) {
      setState(() => _controller.text = text);
    }
  }

  void _submit() {
    final text = _controller.text.trim();
    if (parsePairingPayload(text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a valid pairing URL from heynotime.com (Dashboard → My Users).',
          ),
        ),
      );
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Paste pairing URL'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Copy the link from Dashboard → My Users, paste it below, then tap Connect.',
            style: TextStyle(
              fontSize: 14,
              color: NotiMeColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'https://heynotime.com/thescratchify-5/...',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.content_paste),
                onPressed: _pasteFromClipboard,
                tooltip: 'Paste from clipboard',
              ),
            ),
            keyboardType: TextInputType.url,
            autocorrect: false,
            enableSuggestions: false,
            maxLines: 3,
            minLines: 1,
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Connect'),
        ),
      ],
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
