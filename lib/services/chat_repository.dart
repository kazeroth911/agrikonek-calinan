import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/conversation.dart';
import '../models/message.dart';

/// Firestore access for one-to-one chat. One conversation per pair of
/// users (Conversation.idFor), messages in a subcollection.
class ChatRepository {
  ChatRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(AppConstants.colConversations);

  CollectionReference<Map<String, dynamic>> _messages(String conversationId) =>
      _col.doc(conversationId).collection(AppConstants.colMessages);

  /// The signed-in user's threads, newest activity first. The
  /// array-contains filter satisfies the participant-only read rule;
  /// sorting locally avoids a composite index.
  Stream<List<Conversation>> watchMine(String uid) {
    return _col
        .where('participantIds', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs.map(Conversation.fromDoc).toList();
      items.sort((a, b) => (b.updatedAt ?? DateTime(9999))
          .compareTo(a.updatedAt ?? DateTime(9999)));
      return items;
    });
  }

  Stream<Conversation?> watchConversation(String conversationId) {
    return _col.doc(conversationId).snapshots().map(
        (doc) => doc.exists ? Conversation.fromDoc(doc) : null);
  }

  /// Newest message first (the chat list is drawn reversed).
  Stream<List<Message>> watchMessages(String conversationId,
      {int limit = 200}) {
    return _messages(conversationId)
        .orderBy('sentAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromMap(doc.id, conversationId, doc.data()))
            .toList());
  }

  /// Returns the thread ID for these two users, creating the thread on
  /// first contact. Reopening from another listing updates the listing
  /// the chat is about.
  Future<String> ensureConversation({
    required String myId,
    required String myName,
    required String otherId,
    required String otherName,
    String? listingId,
    String? listingTitle,
  }) async {
    final id = Conversation.idFor(myId, otherId);
    final ref = _col.doc(id);
    final snap = await ref.get();

    if (snap.exists) {
      if (listingId != null && snap.data()?['relatedListingId'] != listingId) {
        await ref.update({
          'relatedListingId': listingId,
          'relatedListingTitle': listingTitle,
        });
      }
      return id;
    }

    final conversation = Conversation(
      conversationId: id,
      participantIds: [myId, otherId]..sort(),
      participantNames: {myId: myName, otherId: otherName},
      unreadCounts: {myId: 0, otherId: 0},
      relatedListingId: listingId,
      relatedListingTitle: listingTitle,
    );
    await ref.set(conversation.toMap());
    return id;
  }

  static String preview(String text) {
    if (text.length <= Conversation.previewLength) return text;
    return '${text.substring(0, Conversation.previewLength - 3)}...';
  }

  /// Saves the message and updates the thread in one atomic batch, so
  /// the chat list and unread badge never disagree with the messages.
  Future<void> sendMessage({
    required Conversation conversation,
    required String senderId,
    required String text,
  }) {
    final recipientId = conversation.otherParticipant(senderId);
    final trimmed = text.trim();
    final messageRef = _messages(conversation.conversationId).doc();

    final batch = _db.batch();
    batch.set(
      messageRef,
      Message(
        messageId: messageRef.id,
        conversationId: conversation.conversationId,
        senderId: senderId,
        text: trimmed,
        readBy: [senderId],
      ).toMap(),
    );
    batch.update(_col.doc(conversation.conversationId), {
      'lastMessage': preview(trimmed),
      'lastSenderId': senderId,
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadCounts.$recipientId': FieldValue.increment(1),
    });
    return batch.commit();
  }

  /// Clears the signed-in user's unread count for one thread.
  Future<void> markRead(String conversationId, String uid) {
    return _col.doc(conversationId).update({'unreadCounts.$uid': 0});
  }
}
