import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/app_notification.dart';
import '../../auth/providers/auth_providers.dart';
import '../notification_router.dart';
import '../notification_text.dart';
import '../providers/notification_providers.dart';

/// In-app notification center. It lists the Firestore records; the phone
/// push for each record is sent separately by the Cloud Function.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static IconData iconFor(String type) => switch (type) {
        'bid' => Icons.gavel,
        'barter' => Icons.swap_horiz,
        'msg' => Icons.chat_bubble_outline,
        _ => Icons.campaign_outlined,
      };

  Future<void> _openNotification(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null || uid != notification.recipientId) return;

    try {
      if (!notification.read) {
        await ref
            .read(notificationRepositoryProvider)
            .markRead(notification.notificationId);
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not mark notification read: $error')),
        );
      }
    }

    if (!context.mounted) return;
    openNotificationTarget(
      Navigator.of(context),
      type: notification.type,
      payload: notification.payload,
    );
  }

  Future<void> _markAllRead(
    BuildContext context,
    WidgetRef ref,
    List<AppNotification> items,
  ) async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    final unread = items
        .where((n) => !n.read && n.recipientId == uid)
        .map((n) => n.notificationId);
    try {
      await ref.read(notificationRepositoryProvider).markAllRead(uid, unread);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not mark all as read: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(myNotificationsProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications / Mga Pahibalo'),
        actions: [
          if (unreadCount > 0)
            IconButton(
              tooltip: 'Mark all as read',
              icon: const Icon(Icons.done_all),
              onPressed: () => _markAllRead(
                context,
                ref,
                notifications.valueOrNull ?? const [],
              ),
            ),
        ],
      ),
      body: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load notifications.\n$error',
                textAlign: TextAlign.center),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No notifications yet.\nWala pay mga pahibalo.',
                    textAlign: TextAlign.center),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final notification = items[index];
              final text = NotificationText.describe(
                  notification.type, notification.payload);
              final when = notification.createdAt == null
                  ? 'Just now'
                  : DateFormat('MMM d, h:mm a')
                      .format(notification.createdAt!.toLocal());

              return Card(
                child: ListTile(
                  leading: Icon(
                    iconFor(notification.type),
                    color: notification.read
                        ? null
                        : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    text.title,
                    style: TextStyle(
                        fontWeight: notification.read
                            ? FontWeight.normal
                            : FontWeight.bold),
                  ),
                  subtitle: Text('${text.body}\n$when'),
                  isThreeLine: true,
                  trailing: notification.read
                      ? const Icon(Icons.chevron_right)
                      : const Icon(Icons.circle, size: 12),
                  onTap: () => _openNotification(context, ref, notification),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
