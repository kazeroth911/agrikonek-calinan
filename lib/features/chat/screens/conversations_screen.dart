import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../auth/providers/auth_providers.dart';
import '../../notifications/widgets/notification_bell.dart';
import '../providers/chat_providers.dart';
import 'chat_screen.dart';

/// Messages tab: every chat the user has, newest activity first.
class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  static String timeLabel(DateTime? when) {
    if (when == null) return '';
    final local = when.toLocal();
    final now = DateTime.now();
    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    return sameDay
        ? DateFormat('h:mm a').format(local)
        : DateFormat('MMM d').format(local);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;
    final conversations = ref.watch(myConversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages / Mga Mensahe'),
        actions: const [NotificationBell()],
      ),
      body: conversations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load messages.\n$error',
                textAlign: TextAlign.center),
          ),
        ),
        data: (items) {
          if (items.isEmpty || uid == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No messages yet.\nWala pay mga mensahe.\n\n'
                  'Open a listing and tap "Message" to start a chat.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final c = items[index];
              final otherName = c.nameOf(c.otherParticipant(uid));
              final unread = c.unreadFor(uid);
              final prefix = c.lastSenderId == uid ? 'You: ' : '';
              final about = c.relatedListingTitle == null
                  ? ''
                  : '${c.relatedListingTitle} · ';

              return ListTile(
                leading: CircleAvatar(
                  child: Text(otherName.isEmpty
                      ? '?'
                      : otherName.characters.first.toUpperCase()),
                ),
                title: Text(
                  otherName,
                  style: TextStyle(
                      fontWeight:
                          unread > 0 ? FontWeight.bold : FontWeight.normal),
                ),
                subtitle: Text(
                  '$about$prefix${c.lastMessage ?? ''}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(timeLabel(c.updatedAt),
                        style: Theme.of(context).textTheme.bodySmall),
                    if (unread > 0) ...[
                      const SizedBox(height: 4),
                      Badge(label: Text(unread > 99 ? '99+' : '$unread')),
                    ],
                  ],
                ),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => ChatScreen(conversationId: c.conversationId),
                )),
              );
            },
          );
        },
      ),
    );
  }
}
