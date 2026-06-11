import 'package:agrikonek_calinan/models/offer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Offer state machine', () {
    test('pending can be accepted, rejected, or countered', () {
      expect(Offer.canTransition(OfferStatus.pending, OfferStatus.accepted),
          isTrue);
      expect(Offer.canTransition(OfferStatus.pending, OfferStatus.rejected),
          isTrue);
      expect(Offer.canTransition(OfferStatus.pending, OfferStatus.countered),
          isTrue);
    });

    test('countered can continue negotiating', () {
      expect(Offer.canTransition(OfferStatus.countered, OfferStatus.countered),
          isTrue);
      expect(Offer.canTransition(OfferStatus.countered, OfferStatus.accepted),
          isTrue);
    });

    test('countered can also be rejected', () {
      expect(Offer.canTransition(OfferStatus.countered, OfferStatus.rejected),
          isTrue);
    });

    test('nothing can move back to pending', () {
      for (final from in OfferStatus.values) {
        expect(Offer.canTransition(from, OfferStatus.pending), isFalse);
      }
    });

    test('accepted and rejected are terminal', () {
      for (final to in OfferStatus.values) {
        expect(Offer.canTransition(OfferStatus.accepted, to), isFalse);
        expect(Offer.canTransition(OfferStatus.rejected, to), isFalse);
      }
    });
  });

  group('Offer model', () {
    test('fromMap round-trips core fields including history', () {
      final offer = Offer.fromMap('off1', {
        'listingId': 'lst1',
        'listingTitle': 'Durian (Puyat)',
        'buyerId': 'buyer1',
        'sellerId': 'seller1',
        'amount': 450,
        'message': 'Pickup Saturday?',
        'status': 'countered',
        'history': [
          {'byUserId': 'buyer1', 'amount': 400, 'action': 'bid'},
          {'byUserId': 'seller1', 'amount': 450, 'action': 'counter'},
        ],
      });

      expect(offer.listingTitle, 'Durian (Puyat)');
      expect(offer.sellerId, 'seller1');
      expect(offer.status, OfferStatus.countered);
      expect(offer.history, hasLength(2));
      expect(offer.history.last.action, 'counter');
      expect(offer.history.last.amount, 450);

      final map = offer.toMap();
      expect(map['listingTitle'], 'Durian (Puyat)');
      expect(map['status'], 'countered');
      expect((map['history'] as List), hasLength(2));
    });

    test('handles missing/empty map defensively', () {
      final offer = Offer.fromMap('x', {});
      expect(offer.amount, 0);
      expect(offer.status, OfferStatus.pending);
      expect(offer.history, isEmpty);
      expect(offer.listingTitle, '');
    });
  });
}
