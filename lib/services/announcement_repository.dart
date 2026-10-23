import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/announcement.dart';
import '../models/app_notification.dart';

/// Saves researcher announcements and fans them out as one 'admin'
/// notification per recipient. Each notification then gets its phone
/// push from the Cloud Function (or the laptop relay on Spark).
class AnnouncementRepository {
  AnnouncementRepository(this._db);

  final FirebaseFirestore _db;

  /// Writes per Firestore batch (the hard limit is 500).
  static const batchSize = 200;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(AppConstants.colAnnouncements);

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection(AppConstants.colNotifications);

  /// Sent history, newest first.
  Stream<List<Announcement>> watchAll() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Announcement.fromDoc).toList());
  }

  /// Returns the new announcement's ID.
  Future<String> send({
    required String senderId,
    required String senderName,
    required String title,
    required String body,
    required AnnouncementAudience audience,
    String? barangay,
    required List<String> recipientIds,
  }) async {
    if (recipientIds.isEmpty) {
      throw ArgumentError('Choose at least one recipient.');
    }

    final announcementRef = _col.doc();
    final announcement = Announcement(
      announcementId: announcementRef.id,
      title: title,
      body: body,
      audience: audience,
      barangay: audience == AnnouncementAudience.barangay ? barangay : null,
      recipientCount: recipientIds.length,
      sentBy: senderId,
      sentByName: senderName,
    );

    final chunks = Announcement.chunk(recipientIds, batchSize);
    for (var i = 0; i < chunks.length; i++) {
      final batch = _db.batch();
      if (i == 0) batch.set(announcementRef, announcement.toMap());
      for (final recipientId in chunks[i]) {
        batch.set(
          _notifications.doc(),
          AppNotification(
            notificationId: '',
            recipientId: recipientId,
            senderId: senderId,
            type: 'admin',
            payload: {
              'announcementId': announcementRef.id,
              'title': title,
              'body': body,
              'senderName': senderName,
            },
          ).toMap(),
        );
      }
      await batch.commit();
    }
    return announcementRef.id;
  }
}
