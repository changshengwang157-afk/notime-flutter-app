import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/notime_api_client.dart';
import '../core/theme/notime_theme.dart';

/// Manual pairing when the camera scanner is unavailable.
class PastePairingUrlDialog extends StatefulWidget {
  const PastePairingUrlDialog({super.key});

  @override
  State<PastePairingUrlDialog> createState() => _PastePairingUrlDialogState();
}

class _PastePairingUrlDialogState extends State<PastePairingUrlDialog> {
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
    if (parsePairingPayload(text) != null) {
      Navigator.of(context).pop(text);
      return;
    }
    final connectSlug = parseConnectSlug(text);
    if (connectSlug != null) {
      Navigator.of(context).pop('connect:$connectSlug');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Paste a pairing URL from Dashboard → My Users '
          '(https://heynotime.com/your-slug/your-token/) '
          'or a connect link (https://heynotime.com/connect/your-slug/).',
        ),
      ),
    );
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
              hintText: 'https://heynotime.com/your-app-slug/your-token/...',
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
