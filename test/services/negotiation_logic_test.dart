import 'package:agrikonek_calinan/models/barter_proposal.dart';
import 'package:agrikonek_calinan/models/offer.dart';
import 'package:agrikonek_calinan/services/barter_repository.dart';
import 'package:agrikonek_calinan/services/offer_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pure business-logic tests for the repository layer — no Firestore
/// instance needed (70%-coverage commitment on non-UI logic).
void main() {
  Offer offer({
    OfferStatus status = OfferStatus.pending,
    List<OfferHistoryEntry> history = const [
      OfferHistoryEntry(byUserId: 'buyer1', amount: 400, action: 'bid'),
    ],
  }) {
    return Offer(
      offerId: 'off1',
      listingId: 'lst1',
      buyerId: 'buyer1',
      sellerId: 'seller1',
      amount: 400,
      status: status,
      history: history,
    );
  }

  group('OfferRepository.canAct (whose turn)', () {
    test('after a fresh bid it is the seller\'s move, not the buyer\'s', () {
      expect(OfferRepository.canAct(offer(), 'seller1'), isTrue);
      expect(OfferRepository.canAct(offer(), 'buyer1'), isFalse);
    });

    test('after a seller counter it is the buyer\'s move', () {
      final countered = offer(status: OfferStatus.countered, history: const [
        OfferHistoryEntry(byUserId: 'buyer1', amount: 400, action: 'bid'),
        OfferHistoryEntry(byUserId: 'seller1', amount: 450, action: 'counter'),
      ]);
      expect(OfferRepository.canAct(countered, 'buyer1'), isTrue);
      expect(OfferRepository.canAct(countered, 'seller1'), isFalse);
    });

    test('nobody can act on terminal offers', () {
      for (final status in [OfferStatus.accepted, OfferStatus.rejected]) {
        expect(OfferRepository.canAct(offer(status: status), 'buyer1'),
            isFalse);
        expect(OfferRepository.canAct(offer(status: status), 'seller1'),
            isFalse);
      }
    });

    test('outsiders can never act', () {
      expect(OfferRepository.canAct(offer(), 'stranger'), isFalse);
    });
  });

  group('OfferRepository.buildStatusUpdate', () {
    test('accept produces status + appended history entry', () {
      final update = OfferRepository.buildStatusUpdate(
          offer: offer(), byUserId: 'seller1', to: OfferStatus.accepted);
      expect(update['status'], 'accepted');
      expect(update['amount'], 400);
      expect(update.containsKey('updatedAt'), isTrue);
      expect(update.containsKey('history'), isTrue);
    });

    test('counter replaces the live amount', () {
      final update = OfferRepository.buildStatusUpdate(
          offer: offer(),
          byUserId: 'seller1',
          to: OfferStatus.countered,
          counterAmount: 500);
      expect(update['amount'], 500);
      expect(update['status'], 'countered');
    });

    test('counter without an amount is rejected', () {
      expect(
          () => OfferRepository.buildStatusUpdate(
              offer: offer(), byUserId: 'seller1', to: OfferStatus.countered),
          throwsStateError);
    });

    test('illegal transitions throw — terminal offers stay terminal', () {
      expect(
          () => OfferRepository.buildStatusUpdate(
              offer: offer(status: OfferStatus.accepted),
              byUserId: 'buyer1',
              to: OfferStatus.rejected),
          throwsStateError);
    });
  });

  BarterProposal proposal({
    BarterStatus status = BarterStatus.pending,
    List<BarterHistoryEntry> history = const [
      BarterHistoryEntry(byUserId: 'prop1', action: 'propose'),
    ],
  }) {
    return BarterProposal(
      barterId: 'bar1',
      listingId: 'lst1',
      proposerId: 'prop1',
      ownerId: 'owner1',
      offeredItems: const [BarterItem(name: 'compost')],
      requestedItems: const [BarterItem(name: 'eggs')],
      status: status,
      history: history,
    );
  }

  group('BarterRepository.canAct (whose turn)', () {
    test('after a fresh proposal it is the owner\'s move', () {
      expect(BarterRepository.canAct(proposal(), 'owner1'), isTrue);
      expect(BarterRepository.canAct(proposal(), 'prop1'), isFalse);
    });

    test('after an owner counter it is the proposer\'s move', () {
      final countered =
          proposal(status: BarterStatus.countered, history: const [
        BarterHistoryEntry(byUserId: 'prop1', action: 'propose'),
        BarterHistoryEntry(
            byUserId: 'owner1', action: 'counter', note: '2 sacks'),
      ]);
      expect(BarterRepository.canAct(countered, 'prop1'), isTrue);
      expect(BarterRepository.canAct(countered, 'owner1'), isFalse);
    });

    test('nobody can act on terminal proposals', () {
      for (final status in [BarterStatus.accepted, BarterStatus.rejected]) {
        expect(BarterRepository.canAct(proposal(status: status), 'owner1'),
            isFalse);
        expect(BarterRepository.canAct(proposal(status: status), 'prop1'),
            isFalse);
      }
    });
  });

  group('BarterRepository.buildStatusUpdate', () {
    test('counter requires a note', () {
      expect(
          () => BarterRepository.buildStatusUpdate(
              proposal: proposal(),
              byUserId: 'owner1',
              to: BarterStatus.countered),
          throwsStateError);
    });

    test('counter with note carries it into history', () {
      final update = BarterRepository.buildStatusUpdate(
          proposal: proposal(),
          byUserId: 'owner1',
          to: BarterStatus.countered,
          counterNote: '2 sacks instead of 1');
      expect(update['status'], 'countered');
      expect(update.containsKey('history'), isTrue);
    });

    test('illegal transitions throw', () {
      expect(
          () => BarterRepository.buildStatusUpdate(
              proposal: proposal(status: BarterStatus.rejected),
              byUserId: 'owner1',
              to: BarterStatus.accepted),
          throwsStateError);
    });
  });
}
