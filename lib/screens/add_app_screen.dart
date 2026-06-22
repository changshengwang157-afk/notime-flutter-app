import 'package:brick_bootstrap5_plus/brick_bootstrap5_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../services/camera_permission.dart';
import '../widgets/notime_scaffold.dart';
import '../widgets/qr_scanner_view.dart';

/// Option 1 — connect another app via QR.
class AddAppScreen extends StatefulWidget {
  const AddAppScreen({super.key});

  @override
  State<AddAppScreen> createState() => _AddAppScreenState();
}

class _AddAppScreenState extends State<AddAppScreen> {
  bool _cameraReady = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final granted = await ensureCameraPermission();
    if (!mounted) return;
    if (!granted) {
      final denied = await isCameraPermanentlyDenied();
      setState(() {
        _cameraError = cameraPermissionMessage(denied);
      });
      return;
    }
    setState(() => _cameraReady = true);
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
                  child: _cameraError != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              _cameraError!,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : !_cameraReady
                          ? const Center(child: CircularProgressIndicator())
                          : QrScannerView(onScanned: _connect),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
