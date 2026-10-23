import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/announcement.dart';
import '../providers/announcement_providers.dart';
import 'compose_announcement_screen.dart';

/// Researcher-admin view of sent announcements, with a button to write
/// a new one.
class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  static String audienceLabel(Announcement a) => switch (a.audience) {
        AnnouncementAudience.all => 'Everyone',
        AnnouncementAudience.barangay => 'Barangay ${a.barangay ?? ''}'.trim(),
        AnnouncementAudience.selected => 'Chosen people',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sent = ref.watch(sentAnnouncementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Announcements / Mga Pahibalo')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const ComposeAnnouncementScreen())),
        icon: const Icon(Icons.campaign),
        label: const Text('New'),
      ),
      body: sent.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load announcements.\n$error',
                textAlign: TextAlign.center),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No announcements sent yet.',
                    textAlign: TextAlign.center),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final a = items[index];
              final when = a.createdAt == null
                  ? 'Sending...'
                  : DateFormat('MMM d, h:mm a').format(a.createdAt!.toLocal());
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.campaign_outlined),
                  title: Text(a.title),
                  subtitle: Text(
                    '${a.body}\n'
                    '$when · ${audienceLabel(a)} · ${a.recipientCount} '
                    '${a.recipientCount == 1 ? 'person' : 'people'}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
