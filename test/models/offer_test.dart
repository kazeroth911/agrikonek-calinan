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

    test('accepted and rejected are terminal', () {
      for (final to in OfferStatus.values) {
        expect(Offer.canTransition(OfferStatus.accepted, to), isFalse);
        expect(Offer.canTransition(OfferStatus.rejected, to), isFalse);
      }
    });
  });
}
