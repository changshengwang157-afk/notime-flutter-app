import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// QR-only camera view. Lets [mobile_scanner] own the controller lifecycle —
/// avoids iOS crashes from manual [MobileScannerController] setup on 7.0.x–7.1.2.
class QrScannerView extends StatefulWidget {
  const QrScannerView({
    super.key,
    required this.onScanned,
  });

  final ValueChanged<String> onScanned;

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.isNotEmpty) {
        _handled = true;
        widget.onScanned(raw);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      fit: BoxFit.cover,
      scanWindowUpdateThreshold: 1,
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
    );
  }
}
