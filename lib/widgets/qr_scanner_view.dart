import 'dart:async';
import 'dart:io' show Platform;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import '../utils/camera_image_utils.dart';

/// Cross-device QR scanner using [camera] + Google ML Kit.
///
/// Uses [ResolutionPreset.high] (not `max`) so iPhone 17 Pro / iOS 26 avoid
/// the unsupported `btp2` pixel-format crash seen with other scanner plugins.
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
  bool _handled = false;
  bool _processing = false;
  bool _starting = true;
  String? _error;
  DateTime _lastFrameAt = DateTime.fromMillisecondsSinceEpoch(0);

  static const _frameInterval = Duration(milliseconds: 250);

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
    unawaited(_stopCamera());
    _scanner?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(_stopImageStream());
    } else if (state == AppLifecycleState.resumed && !_handled && !_starting) {
      unawaited(_resumeImageStream());
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

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      await controller.startImageStream(_onCameraFrame);
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _starting = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _error =
            'Could not open the camera. Use Paste pairing URL on the previous screen.';
      });
    }
  }

  Future<void> _stopImageStream() async {
    final controller = _controller;
    if (controller != null && controller.value.isStreamingImages) {
      try {
        await controller.stopImageStream();
      } catch (_) {}
    }
  }

  Future<void> _resumeImageStream() async {
    final controller = _controller;
    if (controller == null || _handled) return;
    if (controller.value.isStreamingImages) return;
    try {
      await controller.startImageStream(_onCameraFrame);
    } catch (_) {}
  }

  Future<void> _stopCamera() async {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (_) {}
    try {
      await controller.dispose();
    } catch (_) {}
  }

  Future<void> _onCameraFrame(CameraImage image) async {
    if (_handled || _processing || _scanner == null) return;

    final now = DateTime.now();
    if (now.difference(_lastFrameAt) < _frameInterval) return;
    _lastFrameAt = now;

    final controller = _controller;
    if (controller == null) return;

    final inputImage = inputImageFromCameraImage(
      image: image,
      camera: controller.description,
      controller: controller,
    );
    if (inputImage == null) return;

    _processing = true;
    try {
      final barcodes = await _scanner!.processImage(inputImage);
      for (final barcode in barcodes) {
        final raw = barcode.rawValue;
        if (raw != null && raw.isNotEmpty) {
          _handled = true;
          await _stopImageStream();
          widget.onScanned(raw);
          return;
        }
      }
    } catch (_) {
      // Skip bad frames; keep the preview running.
    } finally {
      _processing = false;
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
