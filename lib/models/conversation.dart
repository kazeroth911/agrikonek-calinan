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
    this.unreadCounts = const {},
    this.relatedListingId,
    this.updatedAt,
  });

  final String conversationId;
  final List<String> participantIds;
  final Map<String, String> participantNames; // uid -> name (denormalized)
  final String? lastMessage;
  final Map<String, int> unreadCounts; // uid -> unread count
  final String? relatedListingId;
  final DateTime? updatedAt;

  /// Deterministic ID so the same two users always share one thread.
  static String idFor(String uidA, String uidB) {
    final sorted = [uidA, uidB]..sort();
    return sorted.join('_');
  }

  Map<String, dynamic> toMap() {
    return {
      'participantIds': participantIds,
      'participantNames': participantNames,
      'lastMessage': lastMessage,
      'unreadCounts': unreadCounts,
      'relatedListingId': relatedListingId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Conversation.fromMap(String id, Map<String, dynamic> map) {
    return Conversation(
      conversationId: id,
      participantIds: List<String>.from(map['participantIds'] ?? const []),
      participantNames:
          Map<String, String>.from(map['participantNames'] ?? const {}),
      lastMessage: map['lastMessage'] as String?,
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? const {}),
      relatedListingId: map['relatedListingId'] as String?,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory Conversation.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Conversation.fromMap(doc.id, doc.data() ?? const {});
}
