import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/notime_branding.dart';
import '../core/theme/notime_theme.dart';
import '../models/sent_notification.dart';
import '../services/app_state.dart';

/// Sent notifications history — requirement §7.
class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<AppState>().history;
    final format = DateFormat('MMM d, yyyy · HH:mm');

    if (history.isEmpty) {
      return const Center(
        child: Text(
          'No sent notifications yet.',
          style: TextStyle(color: NotiMeColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        return _HistoryCard(item: item, format: format);
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item, required this.format});

  final SentNotification item;
  final DateFormat format;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                NotiMeBranding.historySource,
                style: const TextStyle(
                  fontSize: 13,
                  color: NotiMeColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: NotiMeColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Sent ${format.format(item.sentAt)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    item.linkClicked ? Icons.link : Icons.link_off,
                    size: 18,
                    color: item.linkClicked
                        ? NotiMeColors.accent
                        : NotiMeColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.linkClicked ? 'Link clicked' : 'Link not clicked',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: item.linkClicked
                          ? NotiMeColors.accent
                          : NotiMeColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

