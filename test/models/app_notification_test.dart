import 'package:agrikonek_calinan/core/l10n/app_language.dart';
import 'package:agrikonek_calinan/features/notifications/notification_text.dart';
import 'package:agrikonek_calinan/models/app_notification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppNotification', () {
    test('toMap writes exactly the fields the security rules allow', () {
      const notification = AppNotification(
        notificationId: '',
        recipientId: 'seller1',
        senderId: 'buyer1',
        type: 'bid',
        payload: {'offerId': 'off1', 'action': 'bid', 'amount': 500},
      );
      final map = notification.toMap();
      expect(map.keys.toSet(),
          {'recipientId', 'senderId', 'type', 'payload', 'read', 'createdAt'});
      expect(map['senderId'], 'buyer1');
      expect(map['read'], isFalse);
    });

    test('fromMap round-trips fields and ignores push status fields', () {
      final created = DateTime.utc(2026, 10, 23, 8);
      final notification = AppNotification.fromMap('n1', {
        'recipientId': 'seller1',
        'senderId': 'buyer1',
        'type': 'barter',
        'payload': {'barterId': 'b1', 'action': 'propose'},
        'read': true,
        'createdAt': Timestamp.fromDate(created),
        'pushStatus': 'sent',
      });
      expect(notification.notificationId, 'n1');
      expect(notification.senderId, 'buyer1');
      expect(notification.type, 'barter');
      expect(notification.payload['barterId'], 'b1');
      expect(notification.read, isTrue);
      expect(notification.createdAt!.isAtSameMomentAs(created), isTrue);
    });

    test('handles an empty map defensively', () {
      final notification = AppNotification.fromMap('x', {});
      expect(notification.recipientId, '');
      expect(notification.senderId, '');
      expect(notification.type, 'admin');
      expect(notification.payload, isEmpty);
      expect(notification.read, isFalse);
    });
  });

  // Same cases as functions/test/notification_text.test.js, so the push
  // and the inbox stay worded the same.
  group('NotificationText', () {
    test('bid notifications show the action and peso amount', () {
      final text = NotificationText.describe(
          'bid', {'action': 'bid', 'listingTitle': 'Durian', 'amount': 1250});
      expect(text.title, 'New cash offer');
      expect(text.body, 'Durian (₱1250.00)');
      expect(NotificationText.describe('bid', {'action': 'counter'}).title,
          'Counter offer');
    });

    test('Cebuano wording only, when Cebuano is chosen', () {
      final text = NotificationText.describe(
          'bid',
          {'action': 'bid', 'listingTitle': 'Durian', 'amount': 1250},
          AppLanguage.cebuano);
      expect(text.title, 'Bag-ong tanyag');
      expect(text.body, 'Durian (₱1250.00)');
      expect(
          NotificationText.describe(
                  'barter', {'action': 'withdraw'}, AppLanguage.cebuano)
              .title,
          'Gibawi ang baylo');
      expect(NotificationText.describe('bid', {}, AppLanguage.cebuano).body,
          'usa ka baligya');
    });

    test('barter notifications use barter wording', () {
      final text = NotificationText.describe(
          'barter', {'action': 'propose', 'listingTitle': 'Cacao'});
      expect(text.title, 'New barter proposal');
      expect(text.body, 'Cacao');
      expect(NotificationText.describe('barter', {'action': 'accept'}).title,
          'Barter accepted');
    });

    test('missing or bad fields fall back safely', () {
      final empty = NotificationText.describe('bid', {});
      expect(empty.title, 'Bid update');
      expect(empty.body, 'a listing');
      expect(NotificationText.describe('bid', {'amount': '500'}).body,
          'a listing');
      expect(NotificationText.describe('unknown', {}).title, 'AgriKonek');
      expect(NotificationText.describe('admin', {}).title,
          'AgriKonek announcement');
      expect(NotificationText.describe('msg', {'preview': '  '}).body,
          'You have a new message.');
    });
  });
}
