import 'package:cloud_firestore/cloud_firestore.dart';

import 'profile.dart';

/// Who an announcement goes to.
enum AnnouncementAudience { all, barangay, selected }

/// A notice a researcher-admin sends to farmers. The announcement itself
/// is kept for the sent history; each recipient gets an 'admin'
/// notification carrying the title and message.
class Announcement {
  const Announcement({
    required this.announcementId,
    required this.title,
    required this.body,
    required this.audience,
    this.barangay,
    required this.recipientCount,
    required this.sentBy,
    required this.sentByName,
    this.createdAt,
  });

  static const maxTitleLength = 80;
  static const maxBodyLength = 500;

  final String announcementId;
  final String title;
  final String body;
  final AnnouncementAudience audience;
  final String? barangay; // only for AnnouncementAudience.barangay
  final int recipientCount;
  final String sentBy;
  final String sentByName;
  final DateTime? createdAt;

  /// Fields written on create. The security rules accept exactly these.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'audience': audience.name,
      'barangay': barangay,
      'recipientCount': recipientCount,
      'sentBy': sentBy,
      'sentByName': sentByName,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
    };
  }

  factory Announcement.fromMap(String id, Map<String, dynamic> map) {
    final audienceName = (map['audience'] ?? 'all') as String;
    return Announcement(
      announcementId: id,
      title: (map['title'] ?? '') as String,
      body: (map['body'] ?? '') as String,
      audience: AnnouncementAudience.values.firstWhere(
        (a) => a.name == audienceName,
        orElse: () => AnnouncementAudience.all,
      ),
      barangay: map['barangay'] as String?,
      recipientCount: (map['recipientCount'] as num?)?.toInt() ?? 0,
      sentBy: (map['sentBy'] ?? '') as String,
      sentByName: (map['sentByName'] ?? '') as String,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory Announcement.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Announcement.fromMap(doc.id, doc.data() ?? const {});

  /// The accounts an announcement reaches. Researcher-admin accounts and
  /// the sender are never included.
  static List<Profile> pickRecipients({
    required List<Profile> profiles,
    required AnnouncementAudience audience,
    required String senderId,
    String? barangay,
    Set<String> selectedIds = const {},
  }) {
    return profiles.where((p) {
      if (p.isAdmin || p.userId == senderId || p.userId.isEmpty) return false;
      switch (audience) {
        case AnnouncementAudience.all:
          return true;
        case AnnouncementAudience.barangay:
          return barangay != null && p.barangay == barangay;
        case AnnouncementAudience.selected:
          return selectedIds.contains(p.userId);
      }
    }).toList();
  }

  /// Splits [items] into groups of at most [size], for Firestore batches.
  static List<List<T>> chunk<T>(List<T> items, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < items.length; i += size) {
      final end = (i + size < items.length) ? i + size : items.length;
      chunks.add(items.sublist(i, end));
    }
    return chunks;
  }
}
