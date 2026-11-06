import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/conversation.dart';
import '../../../models/message.dart';
import '../../../services/chat_repository.dart';
import '../../auth/providers/auth_providers.dart';

final chatRepositoryProvider = Provider<ChatRepository>(
    (ref) => ChatRepository(ref.watch(firestoreProvider)));

/// The signed-in user's threads that have at least one message.
final myConversationsProvider = StreamProvider<List<Conversation>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const <Conversation>[]);
  return ref.watch(chatRepositoryProvider).watchMine(uid).map(
      (items) => items.where((c) => c.lastMessage != null).toList());
});

/// Total unread messages across all threads, for the Messages tab badge.
final unreadChatCountProvider = Provider<int>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return 0;
  final items = ref.watch(myConversationsProvider).valueOrNull ?? const [];
  return items.fold<int>(0, (sum, c) => sum + c.unreadFor(uid));
});

final conversationProvider =
    StreamProvider.family<Conversation?, String>((ref, conversationId) {
  // Re-subscribe on account switch so a cached permission error is not reused.
  ref.watch(authStateProvider);
  return ref.watch(chatRepositoryProvider).watchConversation(conversationId);
});

final messagesProvider =
    StreamProvider.family<List<Message>, String>((ref, conversationId) {
  ref.watch(authStateProvider);
  return ref.watch(chatRepositoryProvider).watchMessages(conversationId);
});

final chatControllerProvider =
    Provider<ChatController>((ref) => ChatController(ref));

/// Opens threads and sends messages. Each sent message also writes a
/// 'msg' notification, which the Cloud Function (or the laptop relay on
/// Spark) turns into a phone push.
class ChatController {
  ChatController(this._ref);

  final Ref _ref;

  ChatRepository get _repo => _ref.read(chatRepositoryProvider);

  /// Returns the conversation ID with [otherId], creating it if needed.
  /// [otherName] is looked up from the profile when not given.
  Future<String> openChat({
    required String otherId,
    String? otherName,
    String? listingId,
    String? listingTitle,
  }) async {
    final me = _ref.read(authStateProvider).valueOrNull;
    if (me == null) throw StateError('Sign in first.');
    if (otherId.isEmpty || otherId == me.uid) {
      throw StateError('You cannot message yourself.');
    }

    final profiles = _ref.read(profileRepositoryProvider);
    final myName = _ref.read(currentProfileProvider).valueOrNull?.fullName ??
        (await profiles.getProfile(me.uid))?.fullName ??
        'AgriKonek user';
    final theirName = (otherName != null && otherName.trim().isNotEmpty)
        ? otherName
        : (await profiles.getProfile(otherId))?.fullName ?? 'AgriKonek user';

    return _repo.ensureConversation(
      myId: me.uid,
      myName: myName,
      otherId: otherId,
      otherName: theirName,
      listingId: listingId,
      listingTitle: listingTitle,
    );
  }

  Future<void> send({
    required Conversation conversation,
    required String text,
  }) async {
    final uid = _ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) throw StateError('Sign in first.');
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (trimmed.length > Message.maxLength) {
      throw ArgumentError(
          'Messages can be at most ${Message.maxLength} characters.');
    }

    await _repo.sendMessage(
        conversation: conversation, senderId: uid, text: trimmed);

    final preview = trimmed.length <= 100
        ? trimmed
        : '${trimmed.substring(0, 97)}...';
    await _ref.read(notificationRepositoryProvider).notify(
      recipientId: conversation.otherParticipant(uid),
      senderId: uid,
      type: 'msg',
      payload: {
        'conversationId': conversation.conversationId,
        'senderName': conversation.nameOf(uid),
        'preview': preview,
        if (conversation.relatedListingId != null)
          'listingId': conversation.relatedListingId,
        if (conversation.relatedListingTitle != null)
          'listingTitle': conversation.relatedListingTitle,
      },
    );
  }
}
