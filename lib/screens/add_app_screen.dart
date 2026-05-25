import 'package:brick_bootstrap5_plus/brick_bootstrap5_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../core/theme/notime_theme.dart';
import '../services/app_state.dart';
import '../widgets/notime_scaffold.dart';

/// Option 1 — connect another app via QR.
class AddAppScreen extends StatefulWidget {
  const AddAppScreen({super.key});

  @override
  State<AddAppScreen> createState() => _AddAppScreenState();
}

class _AddAppScreenState extends State<AddAppScreen> {
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _connect(String payload) async {
    final result = await context.read<AppState>().connectAppFromQr(payload);
    if (!mounted) return;

    final message = switch (result) {
      ConnectAppResult.success => 'App connected.',
      ConnectAppResult.alreadyConnected => 'This app is already connected.',
      ConnectAppResult.invalidQr => 'Invalid QR code.',
      ConnectAppResult.notLoggedIn => 'Please log in first.',
    };

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

    if (result == ConnectAppResult.success) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotiMePage(
      appBar: AppBar(title: const Text('Add app')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: BRow(
          children: [
            BCol(
              classNames: 'col-12',
              child: const Text(
                'Scan a NotiMe QR from another website or app to receive its notifications here.',
                style: TextStyle(fontSize: 16, height: 1.4),
              ),
            ),
            BCol(
              classNames: 'col-12 mt-4',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: MobileScanner(
                    controller: _controller,
                    onDetect: (capture) {
                      for (final b in capture.barcodes) {
                        final raw = b.rawValue;
                        if (raw != null) {
                          _connect(raw);
                          return;
                        }
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
