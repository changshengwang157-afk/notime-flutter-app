import 'dart:async';
import 'dart:io' show File, Platform;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

/// Cross-device QR scanner using [camera] preview + periodic [takePicture].
///
/// Avoids [CameraController.startImageStream] on iOS, which can OOM-crash in
/// release/TestFlight builds when combined with ML Kit frame processing.
class QrScannerView extends StatefulWidget {
  const QrScannerView({
    super.key,
    required this.onScanned,
  });

  final ValueChanged<String> onScanned;

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView>
    with WidgetsBindingObserver {
  CameraController? _controller;
  BarcodeScanner? _scanner;
  Timer? _scanTimer;
  bool _handled = false;
  bool _scanning = false;
  bool _starting = true;
  String? _error;

  static const _scanInterval = Duration(milliseconds: 900);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
    unawaited(_startCamera());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanTimer?.cancel();
    _scanner?.close();
    _scanner = null;
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      unawaited(controller.dispose());
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _scanTimer?.cancel();
    } else if (state == AppLifecycleState.resumed &&
        !_handled &&
        !_starting &&
        _controller != null) {
      _startScanLoop();
    }
  }

  Future<void> _startCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('No camera found');
      }

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      // medium on iOS keeps memory low on iPhone 17 Pro; high is fine on Android.
      final preset =
          Platform.isIOS ? ResolutionPreset.medium : ResolutionPreset.high;

      final controller = CameraController(
        camera,
        preset,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.jpeg
            : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _starting = false;
        _error = null;
      });

      _startScanLoop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _error =
            'Could not open the camera. Check Settings → NotiMe → Camera.';
      });
    }
  }

  void _startScanLoop() {
    _scanTimer?.cancel();
    if (_handled || _controller == null) return;

    _scanTimer = Timer.periodic(_scanInterval, (_) {
      unawaited(_scanOnce());
    });
    unawaited(_scanOnce());
  }

  Future<void> _scanOnce() async {
    if (_handled || _scanning || !mounted) return;
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isTakingPicture) return;

    _scanning = true;
    XFile? photo;
    try {
      photo = await controller.takePicture();
      final inputImage = InputImage.fromFilePath(photo.path);
      final barcodes = await _scanner!.processImage(inputImage);
      for (final barcode in barcodes) {
        final raw = barcode.rawValue;
        if (raw != null && raw.isNotEmpty) {
          _handled = true;
          _scanTimer?.cancel();
          await _disposeController();
          if (mounted) {
            widget.onScanned(raw);
          }
          return;
        }
      }
    } catch (_) {
      // Ignore single-frame failures; keep scanning.
    } finally {
      if (photo != null) {
        try {
          await File(photo.path).delete();
        } catch (_) {}
      }
      _scanning = false;
    }
  }

  Future<void> _disposeController() async {
    _scanTimer?.cancel();
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      try {
        await controller.dispose();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
        ),
      );
    }

    if (_starting || _controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller!.value.previewSize!.height,
            height: _controller!.value.previewSize!.width,
            child: CameraPreview(_controller!),
          ),
        ),
      ),
    );
  }
}
