/// Title and body for one notification. The same wording is used by the
/// in-app inbox and by the phone push built in functions/notification_text.js,
/// so keep the two files in sync; functions/test/notification_text.test.js
/// fails if they drift apart.
///
/// Wording is "English / Cebuano", like the rest of the app. The Cebuano
/// is listed for review in docs/NOTIFICATION_TEXT_CEBUANO.md.
class NotificationText {
  const NotificationText(this.title, this.body);

  final String title;
  final String body;

  static const _bidTitles = {
    'bid': 'New cash offer / Bag-ong tanyag',
    'accept': 'Offer accepted / Gidawat ang tanyag',
    'reject': 'Offer rejected / Wala gidawat ang tanyag',
    'counter': 'Counter offer / Counter nga tanyag',
    'withdraw': 'Offer withdrawn / Gibawi ang tanyag',
  };
  static const _bidFallback = 'Bid update / Update sa tanyag';

  static const _barterTitles = {
    'propose': 'New barter proposal / Bag-ong tanyag sa baylo',
    'accept': 'Barter accepted / Gidawat ang baylo',
    'reject': 'Barter declined / Wala gidawat ang baylo',
    'counter': 'Barter counter-proposal / Gi-counter ang baylo',
    'withdraw': 'Barter withdrawn / Gibawi ang baylo',
  };
  static const _barterFallback = 'Barter update / Update sa baylo';

  static const _listingFallback = 'a listing / usa ka baligya';
  static const _msgTitle = 'New message / Bag-ong mensahe';
  static const _msgBody = 'You have a new message. / Naa kay bag-ong mensahe.';
  static const _adminTitle = 'AgriKonek announcement / Pahibalo sa AgriKonek';
  static const _adminBody =
      'Open the app to read it. / Ablihi ang app aron mabasa.';
  static const _defaultTitle = 'AgriKonek';
  static const _defaultBody =
      'You have a new notification. / Naa kay bag-ong pahibalo.';

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
  static NotificationText describe(String type, Map<String, dynamic> payload) {
    final listing = _str(payload['listingTitle'], _listingFallback);
    final action = _str(payload['action'], '');

    switch (type) {
      case 'bid':
        return NotificationText(
          _bidTitles[action] ?? _bidFallback,
          '$listing${_peso(payload['amount'])}',
        );
      case 'barter':
        return NotificationText(_barterTitles[action] ?? _barterFallback, listing);
      case 'msg':
        return NotificationText(
          _str(payload['senderName'], _msgTitle),
          _str(payload['preview'], _msgBody),
        );
      case 'admin':
        return NotificationText(
          _str(payload['title'], _adminTitle),
          _str(payload['body'], _adminBody),
        );
      default:
        return const NotificationText(_defaultTitle, _defaultBody);
    }
  }
}
