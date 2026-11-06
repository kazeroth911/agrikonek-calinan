import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../models/app_notification.dart';

/// Writes notification documents CLIENT-SIDE, immediately after the
/// triggering bid or barter write. Each new document triggers the
/// sendPushOnNotification Cloud Function (functions/index.js), which sends
/// the FCM push, so the record always exists before the push leaves
/// (DFD process 6.0). The in-app inbox reads these same documents.
///
/// Best-effort: a notification is never worth failing the bid or barter
/// it announces, so failures are logged and swallowed.
class NotificationRepository {
  NotificationRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(AppConstants.colNotifications);

  /// Realtime inbox for a single user. Filter in Firestore so the query
  /// satisfies the recipient-only read rule. Sort locally to avoid an index.
  Stream<List<AppNotification>> watchMine(String uid) {
    return _col.where('recipientId', isEqualTo: uid).snapshots().map((snapshot) {
      final items = snapshot.docs.map(AppNotification.fromDoc).toList();
      items.sort((a, b) => (b.createdAt ?? DateTime(0))
          .compareTo(a.createdAt ?? DateTime(0)));
      return items;
    });
  }

  /// One record, live. The read rule limits it to its recipient.
  Stream<AppNotification?> watchOne(String notificationId) {
    return _col.doc(notificationId).snapshots().map(
        (doc) => doc.exists ? AppNotification.fromDoc(doc) : null);
  }

  /// The rules permit a recipient to mark only their own record as read.
  Future<void> markRead(String notificationId) {
    return _col.doc(notificationId).update({'read': true});
  }

  /// Marks every unread notification of [uid] as read in one batch.
  Future<void> markAllRead(String uid, Iterable<String> unreadIds) async {
    final ids = unreadIds.toList();
    // Firestore batches hold at most 500 writes.
    for (var i = 0; i < ids.length; i += 450) {
      final batch = _db.batch();
      for (final id in ids.skip(i).take(450)) {
        batch.update(_col.doc(id), {'read': true});
      }
      await batch.commit();
    }
  }

  Future<void> notify({
    required String recipientId,
    required String senderId,
    required String type, // bid | barter | msg | admin
    Map<String, dynamic> payload = const {},
  }) async {
    try {
      final notification = AppNotification(
        notificationId: '', // assigned by Firestore
        recipientId: recipientId,
        senderId: senderId,
        type: type,
        payload: payload,
      );
      await _col.add(notification.toMap());
    } catch (e) {
      debugPrint('NotificationRepository: write failed (non-fatal): $e');
    }
  }
}
