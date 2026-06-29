import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';
import '../core/theme/notime_theme.dart';
import '../models/notification_item.dart';
import '../services/app_state.dart';
import '../utils/external_link.dart';
import '../widgets/help_sheet.dart';
import '../widgets/notification_image.dart';
import '../widgets/notime_scaffold.dart';

/// https://heynotime.com/mobile-preview/notification-details/
class NotificationDetailScreen extends StatefulWidget {
  const NotificationDetailScreen({super.key, required this.notificationId});

  final String notificationId;

  @override
  State<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  bool _loading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _ensureLoaded();
  }

  Future<void> _ensureLoaded() async {
    final state = context.read<AppState>();
    if (state.notificationById(widget.notificationId) != null) return;
    if (ApiConfig.useMockData) return;

    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      await state.loadNotificationDetail(widget.notificationId);
    } catch (_) {
      if (mounted) {
        setState(() => _loadError = 'Could not load this notification.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final item = state.notificationById(widget.notificationId);
    final app =
        item != null ? state.connectedAppById(item.appId) : state.selectedApp;

    if (_loading && item == null) {
      return NotiMePage(
        appBar: AppBar(title: const Text('Notification')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (item == null) {
      return NotiMePage(
        appBar: AppBar(title: const Text('Notification')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _loadError ?? 'Notification not found.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return _NotificationDetailBody(item: item, appName: app?.displayName ?? 'App');
  }
}

class _NotificationDetailBody extends StatelessWidget {
  const _NotificationDetailBody({
    required this.item,
    required this.appName,
  });

  final NotificationItem item;
  final String appName;

  @override
  Widget build(BuildContext context) {
    final expired = item.isExpired;

    return NotiMePage(
      appBar: AppBar(
        title: const Text('Notification'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => showHelpSheet(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: NotificationImage(
                path: item.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              item.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: expired
                    ? NotiMeColors.expired
                    : NotiMeColors.textPrimary,
                decoration: expired ? TextDecoration.lineThrough : null,
              ),
            ),
            if (item.expiresAt != null) ...[
              const SizedBox(height: 8),
              Text(
                expired
                    ? 'Expired on ${DateFormat.yMMMd().add_Hm().format(item.expiresAt!)}'
                    : 'Valid until ${DateFormat.yMMMd().add_Hm().format(item.expiresAt!)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      expired ? NotiMeColors.danger : NotiMeColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              item.body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: NotiMeColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: expired
                    ? null
                    : () => _openExternalLink(context, item, appName),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Go to Link'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openExternalLink(
    BuildContext context,
    NotificationItem item,
    String appName,
  ) async {
    final state = context.read<AppState>();
    final token = state.session?.userToken ?? 'unknown';
    final uri = appendUserQuery(item.externalUrl, token);

    state.markLinkClicked(item.id, item.title, appName);

    if (!context.mounted) return;

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
