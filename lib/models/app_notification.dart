import 'package:cloud_firestore/cloud_firestore.dart';

/// Persistent record of every system-initiated alert (written before
/// the FCM push leaves the system, per DFD process 6.0).
/// Named AppNotification to avoid clashing with Flutter's Notification.
class AppNotification {
  const AppNotification({
    required this.notificationId,
    required this.recipientId,
    this.senderId = '',
    required this.type, // bid | barter | msg | admin
    this.payload = const {},
    this.read = false,
    this.createdAt,
  });

  final String notificationId;
  final String recipientId;

  /// Account that caused the alert. The security rules require it to be
  /// the signed-in writer and a party to the referenced offer or barter.
  final String senderId;
  final String type;
  final Map<String, dynamic> payload;
  final bool read;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() {
    return {
      'recipientId': recipientId,
      'senderId': senderId,
      'type': type,
      'payload': payload,
      'read': read,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
    };
  }

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    return AppNotification(
      notificationId: id,
      recipientId: (map['recipientId'] ?? '') as String,
      senderId: (map['senderId'] ?? '') as String,
      type: (map['type'] ?? 'admin') as String,
      payload: Map<String, dynamic>.from(map['payload'] ?? const {}),
      read: (map['read'] ?? false) as bool,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory AppNotification.fromDoc(
          DocumentSnapshot<Map<String, dynamic>> doc) =>
      AppNotification.fromMap(doc.id, doc.data() ?? const {});
}
