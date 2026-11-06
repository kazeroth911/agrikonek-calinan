import '../../core/l10n/app_language.dart';

/// Title and body for one notification. The same wording is used by the
/// in-app inbox and by the phone push built in functions/notification_text.js,
/// so keep the two files in sync; functions/test/notification_text.test.js
/// fails if they drift apart.
///
/// Shown in the language the user chose in Settings. The Cebuano is
/// listed for review in docs/NOTIFICATION_TEXT_CEBUANO.md.
class NotificationText {
  const NotificationText(this.title, this.body);

  final String title;
  final String body;

  static const _en = _Words(
    bid: {
      'bid': 'New cash offer',
      'accept': 'Offer accepted',
      'reject': 'Offer rejected',
      'counter': 'Counter offer',
      'withdraw': 'Offer withdrawn',
    },
    bidFallback: 'Bid update',
    barter: {
      'propose': 'New barter proposal',
      'accept': 'Barter accepted',
      'reject': 'Barter declined',
      'counter': 'Barter counter-proposal',
      'withdraw': 'Barter withdrawn',
    },
    barterFallback: 'Barter update',
    listingFallback: 'a listing',
    msgTitle: 'New message',
    msgBody: 'You have a new message.',
    adminTitle: 'AgriKonek announcement',
    adminBody: 'Open the app to read it.',
    defaultTitle: 'AgriKonek',
    defaultBody: 'You have a new notification.',
  );

  static const _ceb = _Words(
    bid: {
      'bid': 'Bag-ong tanyag',
      'accept': 'Gidawat ang tanyag',
      'reject': 'Wala gidawat ang tanyag',
      'counter': 'Counter nga tanyag',
      'withdraw': 'Gibawi ang tanyag',
    },
    bidFallback: 'Update sa tanyag',
    barter: {
      'propose': 'Bag-ong tanyag sa baylo',
      'accept': 'Gidawat ang baylo',
      'reject': 'Wala gidawat ang baylo',
      'counter': 'Gi-counter ang baylo',
      'withdraw': 'Gibawi ang baylo',
    },
    barterFallback: 'Update sa baylo',
    listingFallback: 'usa ka baligya',
    msgTitle: 'Bag-ong mensahe',
    msgBody: 'Naa kay bag-ong mensahe.',
    adminTitle: 'Pahibalo sa AgriKonek',
    adminBody: 'Ablihi ang app aron mabasa.',
    defaultTitle: 'AgriKonek',
    defaultBody: 'Naa kay bag-ong pahibalo.',
  );

  static String _str(Object? value, String fallback) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }

  static String _peso(Object? amount) {
    if (amount is num && amount.isFinite) {
      return ' (₱${amount.toStringAsFixed(2)})';
    }
    return '';
  }

  /// [type] is bid | barter | msg | admin.
  static NotificationText describe(
    String type,
    Map<String, dynamic> payload, [
    AppLanguage language = AppLanguage.english,
  ]) {
    final w = language == AppLanguage.cebuano ? _ceb : _en;
    final listing = _str(payload['listingTitle'], w.listingFallback);
    final action = _str(payload['action'], '');

    switch (type) {
      case 'bid':
        return NotificationText(
          w.bid[action] ?? w.bidFallback,
          '$listing${_peso(payload['amount'])}',
        );
      case 'barter':
        return NotificationText(w.barter[action] ?? w.barterFallback, listing);
      case 'msg':
        return NotificationText(
          _str(payload['senderName'], w.msgTitle),
          _str(payload['preview'], w.msgBody),
        );
      case 'admin':
        return NotificationText(
          _str(payload['title'], w.adminTitle),
          _str(payload['body'], w.adminBody),
        );
      default:
        return NotificationText(w.defaultTitle, w.defaultBody);
    }
  }
}

/// One language's notification wording.
class _Words {
  const _Words({
    required this.bid,
    required this.bidFallback,
    required this.barter,
    required this.barterFallback,
    required this.listingFallback,
    required this.msgTitle,
    required this.msgBody,
    required this.adminTitle,
    required this.adminBody,
    required this.defaultTitle,
    required this.defaultBody,
  });

  final Map<String, String> bid;
  final String bidFallback;
  final Map<String, String> barter;
  final String barterFallback;
  final String listingFallback;
  final String msgTitle;
  final String msgBody;
  final String adminTitle;
  final String adminBody;
  final String defaultTitle;
  final String defaultBody;
}
