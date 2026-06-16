import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../core/theme/notime_theme.dart';
import '../services/app_state.dart';
import '../services/camera_permission.dart';
import '../widgets/notime_app_bar_title.dart';
import '../widgets/notime_scaffold.dart';

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
      final denied = await Permission.camera.isPermanentlyDenied;
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
        _showSnack('Invalid QR code. Please try again.');
        Future.delayed(const Duration(seconds: 2), () => _lastScan = null);
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
  MobileScannerController? _controller;
  bool _handled = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null) {
        _handled = true;
        Navigator.of(context).pop(raw);
        break;
      }
    }
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
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            )
          : Stack(
        fit: StackFit.expand,
        children: [
          if (_controller != null)
            MobileScanner(
              controller: _controller!,
              onDetect: _onDetect,
              errorBuilder: (context, error) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Camera unavailable: ${error.errorDetails?.message ?? error.errorCode.name}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                );
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
