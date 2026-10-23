import 'package:cloud_firestore/cloud_firestore.dart';

/// A single chat message inside conversations/{id}/messages.
class Message {
  const Message({
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    required this.text,
    this.attachmentUrl,
    this.sentAt,
    this.readBy = const [],
  });

  final String messageId;
  final String conversationId;
  final String senderId;
  final String text;
  final String? attachmentUrl;
  final DateTime? sentAt;
  final List<String> readBy;

  /// Longest message the app and the security rules accept.
  static const maxLength = 1000;

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'attachmentUrl': attachmentUrl,
      'sentAt': sentAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(sentAt!),
      'readBy': readBy,
    };
  }

  factory Message.fromMap(
      String id, String conversationId, Map<String, dynamic> map) {
    return Message(
      messageId: id,
      conversationId: conversationId,
      senderId: (map['senderId'] ?? '') as String,
      text: (map['text'] ?? '') as String,
      attachmentUrl: map['attachmentUrl'] as String?,
      sentAt: (map['sentAt'] as Timestamp?)?.toDate(),
      readBy: List<String>.from(map['readBy'] ?? const []),
    );
  }
}
