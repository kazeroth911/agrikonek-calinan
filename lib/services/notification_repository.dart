import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../models/app_notification.dart';

/// Writes notification documents CLIENT-SIDE, immediately after the
/// triggering write — Cloud Functions are deferred per the approved plan
/// (Spark budget + solo timeline). Sprint 4 attaches FCM and the
/// in-app notification center on top of these same documents.
///
/// Best-effort: a notification is never worth failing the bid or barter
/// it announces, so failures are logged and swallowed.
class NotificationRepository {
  NotificationRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(AppConstants.colNotifications);

  Future<void> notify({
    required String recipientId,
    required String type, // bid | barter | msg | admin
    Map<String, dynamic> payload = const {},
  }) async {
    try {
      final notification = AppNotification(
        notificationId: '', // assigned by Firestore
        recipientId: recipientId,
        type: type,
        payload: payload,
      );
      await _col.add(notification.toMap());
    } catch (e) {
      debugPrint('NotificationRepository: write failed (non-fatal): $e');
    }
  }
}
