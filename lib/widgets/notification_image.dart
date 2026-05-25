import 'package:flutter/material.dart';

/// Loads notification preview from asset or network URL.
class NotificationImage extends StatelessWidget {
  const NotificationImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _errorBox(),
      );
    }
    return Image.network(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _errorBox(),
    );
  }

  Widget _errorBox() {
    return SizedBox(
      width: width,
      height: height,
      child: const Icon(Icons.image_outlined, size: 48),
    );
  }
}
