/// Title and body for one notification. The same wording is used by the
/// in-app inbox and by the phone push built in functions/notification_text.js,
/// so keep the two files in sync.
class NotificationText {
  const NotificationText(this.title, this.body);

  final String title;
  final String body;

  static const _bidTitles = {
    'bid': 'New cash offer',
    'accept': 'Offer accepted',
    'reject': 'Offer rejected',
    'counter': 'Counter offer',
  };

  static const _barterTitles = {
    'propose': 'New barter proposal',
    'accept': 'Barter accepted',
    'reject': 'Barter rejected',
    'counter': 'Barter counter-proposal',
  };

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
    final listing = _str(payload['listingTitle'], 'a listing');
    final action = _str(payload['action'], '');

    switch (type) {
      case 'bid':
        return NotificationText(
          _bidTitles[action] ?? 'Bid update',
          '$listing${_peso(payload['amount'])}',
        );
      case 'barter':
        return NotificationText(_barterTitles[action] ?? 'Barter update', listing);
      case 'msg':
        return NotificationText(
          _str(payload['senderName'], 'New message'),
          _str(payload['preview'], 'You have a new message.'),
        );
      case 'admin':
        return NotificationText(
          _str(payload['title'], 'AgriKonek announcement'),
          _str(payload['body'], 'Open the app to read it.'),
        );
      default:
        return const NotificationText(
            'AgriKonek', 'You have a new notification.');
    }
  }
}
