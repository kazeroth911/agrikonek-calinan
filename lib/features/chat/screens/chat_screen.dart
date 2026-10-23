import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/app_notification.dart';
import '../../../models/conversation.dart';
import '../../../models/message.dart';
import '../../../services/push_notification_service.dart';
import '../../auth/providers/auth_providers.dart';
import '../../notifications/providers/notification_providers.dart';
import '../../profile/providers/visibility_providers.dart';
import '../../profile/widgets/profile_unavailable_banner.dart';
import '../providers/chat_providers.dart';

/// One-to-one chat. Opening it clears the unread count and marks this
/// thread's message notifications as read.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _text = TextEditingController();
  bool _clearingUnread = false;
  bool _clearingNotifications = false;

  @override
  void initState() {
    super.initState();
    // No snackbar for pushes about the chat that is already on screen.
    PushNotificationService.instance.activeConversationId =
        widget.conversationId;

    ref.listenManual<AsyncValue<Conversation?>>(
      conversationProvider(widget.conversationId),
      (_, next) => _clearUnread(next.valueOrNull),
      fireImmediately: true,
    );
    ref.listenManual<AsyncValue<List<AppNotification>>>(
      myNotificationsProvider,
      (_, next) => _clearNotifications(next.valueOrNull),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    final push = PushNotificationService.instance;
    if (push.activeConversationId == widget.conversationId) {
      push.activeConversationId = null;
    }
    _text.dispose();
    super.dispose();
  }

  Future<void> _clearUnread(Conversation? conversation) async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (conversation == null || uid == null || _clearingUnread) return;
    if (conversation.unreadFor(uid) == 0) return;
    _clearingUnread = true;
    try {
      await ref
          .read(chatRepositoryProvider)
          .markRead(widget.conversationId, uid);
    } catch (error) {
      debugPrint('Could not clear chat unread count: $error');
    } finally {
      _clearingUnread = false;
    }
  }

  Future<void> _clearNotifications(List<AppNotification>? items) async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (items == null || uid == null || _clearingNotifications) return;
    final ids = items
        .where((n) =>
            !n.read &&
            n.type == 'msg' &&
            n.payload['conversationId'] == widget.conversationId)
        .map((n) => n.notificationId)
        .toList();
    if (ids.isEmpty) return;
    _clearingNotifications = true;
    try {
      await ref.read(notificationRepositoryProvider).markAllRead(uid, ids);
    } catch (error) {
      debugPrint('Could not mark chat notifications read: $error');
    } finally {
      _clearingNotifications = false;
    }
  }

  void _send(Conversation conversation) {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    _text.clear();
    // Not awaited: Firestore shows the message at once and syncs it when
    // the phone has signal, which matters on weak rural connections.
    unawaited(_deliver(conversation, text, ScaffoldMessenger.of(context)));
  }

  Future<void> _deliver(Conversation conversation, String text,
      ScaffoldMessengerState messenger) async {
    try {
      await ref
          .read(chatControllerProvider)
          .send(conversation: conversation, text: text);
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Message not sent / Wala napadala: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;
    final conversationAsync =
        ref.watch(conversationProvider(widget.conversationId));
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));
    final conversation = conversationAsync.valueOrNull;

    final title = (conversation == null || uid == null)
        ? 'Chat'
        : conversation.nameOf(conversation.otherParticipant(uid));
    final otherHidden = conversation != null &&
        uid != null &&
        ref.watch(isProfileHiddenProvider(conversation.otherParticipant(uid)));

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          if (otherHidden)
            const ProfileUnavailableBanner(
                detail: 'You can read past messages but not send new ones.'),
          if (conversation?.relatedListingTitle != null)
            Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.storefront_outlined),
                title: Text('About: ${conversation!.relatedListingTitle}'),
              ),
            ),
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Could not load messages.\n$error',
                      textAlign: TextAlign.center),
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('Say hello! / Pangumusta!'),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) => _Bubble(
                    message: messages[index],
                    mine: messages[index].senderId == uid,
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _text,
                      enabled: !otherHidden,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: Message.maxLength,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Type a message / Pag-type og mensahe',
                        counterText: '',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Send / Ipadala',
                    icon: const Icon(Icons.send),
                    onPressed: (conversation == null || otherHidden)
                        ? null
                        : () => _send(conversation),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});

  final Message message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final time = message.sentAt == null
        ? 'Sending...'
        : DateFormat('MMM d, h:mm a').format(message.sentAt!.toLocal());

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: mine ? scheme.primaryContainer : scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment:
                mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(message.text),
              const SizedBox(height: 2),
              Text(time, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}
