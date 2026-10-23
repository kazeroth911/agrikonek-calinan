import 'package:cloud_firestore/cloud_firestore.dart';

/// One-to-one chat thread. Messages live in a subcollection:
/// conversations/{id}/messages/{messageId}.
/// participantNames is denormalized so chat lists render in one read.
class Conversation {
  const Conversation({
    required this.conversationId,
    required this.participantIds,
    this.participantNames = const {},
    this.lastMessage,
    this.lastSenderId,
    this.unreadCounts = const {},
    this.relatedListingId,
    this.relatedListingTitle,
    this.updatedAt,
  });

  final String conversationId;

  /// Always exactly two UIDs, sorted, so the security rules can check
  /// that the document ID is idFor(participantIds[0], participantIds[1]).
  final List<String> participantIds;
  final Map<String, String> participantNames; // uid -> name (denormalized)
  final String? lastMessage;
  final String? lastSenderId;
  final Map<String, int> unreadCounts; // uid -> unread count
  final String? relatedListingId;
  final String? relatedListingTitle;
  final DateTime? updatedAt;

  /// Longest preview kept on the conversation for the chat list.
  static const previewLength = 200;

  /// Deterministic ID so the same two users always share one thread.
  static String idFor(String uidA, String uidB) {
    final sorted = [uidA, uidB]..sort();
    return sorted.join('_');
  }

  /// The participant who is not [uid].
  String otherParticipant(String uid) => participantIds.firstWhere(
        (id) => id != uid,
        orElse: () => '',
      );

  String nameOf(String uid) {
    final name = participantNames[uid];
    return (name == null || name.trim().isEmpty) ? 'AgriKonek user' : name;
  }

  int unreadFor(String uid) => unreadCounts[uid] ?? 0;

  /// Fields written when the thread is first created. The security rules
  /// accept exactly these keys.
  Map<String, dynamic> toMap() {
    return {
      'participantIds': participantIds,
      'participantNames': participantNames,
      'lastMessage': lastMessage,
      'lastSenderId': lastSenderId,
      'unreadCounts': unreadCounts,
      'relatedListingId': relatedListingId,
      'relatedListingTitle': relatedListingTitle,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Conversation.fromMap(String id, Map<String, dynamic> map) {
    final unread = <String, int>{};
    final rawUnread = map['unreadCounts'];
    if (rawUnread is Map) {
      rawUnread.forEach((key, value) {
        if (value is num) unread[key.toString()] = value.toInt();
      });
    }
    return Conversation(
      conversationId: id,
      participantIds: List<String>.from(map['participantIds'] ?? const []),
      participantNames:
          Map<String, String>.from(map['participantNames'] ?? const {}),
      lastMessage: map['lastMessage'] as String?,
      lastSenderId: map['lastSenderId'] as String?,
      unreadCounts: unread,
      relatedListingId: map['relatedListingId'] as String?,
      relatedListingTitle: map['relatedListingTitle'] as String?,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory Conversation.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Conversation.fromMap(doc.id, doc.data() ?? const {});
}
