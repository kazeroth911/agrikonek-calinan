import 'package:flutter/material.dart';

import '../offers/screens/barter_detail_screen.dart';
import '../offers/screens/offer_detail_screen.dart';

/// Opens the screen a notification is about. Used by both the inbox and
/// a tapped phone push. Returns false when there is no screen to open
/// (for example an announcement, or chat before it is built), so the
/// caller can fall back to the inbox.
bool openNotificationTarget(
  NavigatorState navigator, {
  required String type,
  required Map<String, dynamic> payload,
}) {
  String id(String key) => (payload[key] ?? '').toString();

  Widget? screen;
  if (type == 'bid' && id('offerId').isNotEmpty) {
    screen = OfferDetailScreen(offerId: id('offerId'));
  } else if (type == 'barter' && id('barterId').isNotEmpty) {
    screen = BarterDetailScreen(barterId: id('barterId'));
  }
  // 'msg' should open the conversation once one-to-one chat is built.

  if (screen == null) return false;
  final target = screen;
  navigator.push(MaterialPageRoute<void>(builder: (_) => target));
  return true;
}
