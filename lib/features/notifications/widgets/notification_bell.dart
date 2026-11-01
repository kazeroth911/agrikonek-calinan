import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notification_providers.dart';
import '../screens/notifications_screen.dart';
import '../../../core/l10n/app_language.dart';

/// Opens the inbox and shows the Firestore unread count for this user.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key, this.color});

  /// Icon colour, e.g. white on the green marketplace header.
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unreadNotificationCountProvider);
    return IconButton(
      color: color,
      tooltip: context.tr('Notifications', 'Mga Pahibalo'),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        child: const Icon(Icons.notifications_outlined),
      ),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
      ),
    );
  }
}
