import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/announcement_providers.dart';
import '../../../core/l10n/app_language.dart';

/// Full text of an announcement for the farmer who received it. Opened
/// from the inbox (text already known) or from a tapped push (loaded
/// from the notification record, since a push carries only IDs).
class AnnouncementDetailScreen extends ConsumerWidget {
  const AnnouncementDetailScreen({
    super.key,
    required this.notificationId,
    this.payload,
    this.createdAt,
  });

  final String notificationId;
  final Map<String, dynamic>? payload;
  final DateTime? createdAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasText = (payload?['title'] ?? payload?['body']) != null;
    if (hasText) {
      return _AnnouncementView(payload: payload!, createdAt: createdAt);
    }

    final record = ref.watch(notificationByIdProvider(notificationId));
    return record.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text(context.tr('Announcement', 'Pahibalo'))),
        body: Center(
            child: Text(
                '${context.tr('Could not load this announcement.', 'Wala ma-load kini nga pahibalo.')}\n$error',
                textAlign: TextAlign.center)),
      ),
      data: (notification) => notification == null
          ? Scaffold(
              appBar:
                  AppBar(title: Text(context.tr('Announcement', 'Pahibalo'))),
              body: Center(
                  child: Text(context.tr(
                      'This announcement is no longer available.',
                      'Wala na kini nga pahibalo.'))),
            )
          : _AnnouncementView(
              payload: notification.payload,
              createdAt: notification.createdAt,
            ),
    );
  }
}

class _AnnouncementView extends StatelessWidget {
  const _AnnouncementView({required this.payload, this.createdAt});

  final Map<String, dynamic> payload;
  final DateTime? createdAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = (payload['title'] ??
            context.tr('AgriKonek announcement', 'Pahibalo sa AgriKonek'))
        .toString();
    final body = (payload['body'] ?? '').toString();
    final sender = (payload['senderName'] ?? '').toString();
    final when = createdAt == null
        ? ''
        : DateFormat('MMMM d, y · h:mm a').format(createdAt!.toLocal());

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Announcement', 'Pahibalo'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Icon(Icons.campaign_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  [
                    if (sender.isNotEmpty)
                      context.tr('From $sender', 'Gikan kang $sender'),
                    if (when.isNotEmpty) when,
                  ]
                      .join(' · '),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          SelectableText(body, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
