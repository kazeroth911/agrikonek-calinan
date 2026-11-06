import 'package:agrikonek_calinan/models/barter_proposal.dart';
import 'package:agrikonek_calinan/models/offer.dart';
import 'package:agrikonek_calinan/services/barter_repository.dart';
import 'package:agrikonek_calinan/services/offer_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Paper §3.5.3: the party who made the last offer may withdraw it while
/// it is waiting; Withdrawn is a final state.
void main() {
  Offer offer({
    OfferStatus status = OfferStatus.pending,
    List<OfferHistoryEntry> history = const [
      OfferHistoryEntry(byUserId: 'buyer1', amount: 400, action: 'bid'),
    ],
  }) =>
      Offer(
        offerId: 'off1',
        listingId: 'lst1',
        buyerId: 'buyer1',
        sellerId: 'seller1',
        amount: 400,
        status: status,
        history: history,
      );

  BarterProposal proposal({
    BarterStatus status = BarterStatus.pending,
    List<BarterHistoryEntry> history = const [
      BarterHistoryEntry(byUserId: 'prop1', action: 'propose'),
    ],
  }) =>
      BarterProposal(
        barterId: 'bar1',
        listingId: 'lst1',
        proposerId: 'prop1',
        ownerId: 'owner1',
        offeredItems: const [BarterItem(name: 'compost')],
        requestedItems: const [BarterItem(name: 'eggs')],
        status: status,
        history: history,
      );

  group('bid withdrawal', () {
    test('only the last offerer may withdraw a waiting bid', () {
      expect(OfferRepository.canWithdraw(offer(), 'buyer1'), isTrue);
      expect(OfferRepository.canWithdraw(offer(), 'seller1'), isFalse);
      expect(OfferRepository.canWithdraw(offer(), 'stranger'), isFalse);
    });

    test('after a seller counter, only the seller may withdraw it', () {
      final countered = offer(status: OfferStatus.countered, history: const [
        OfferHistoryEntry(byUserId: 'buyer1', amount: 400, action: 'bid'),
        OfferHistoryEntry(byUserId: 'seller1', amount: 450, action: 'counter'),
      ]);
      expect(OfferRepository.canWithdraw(countered, 'seller1'), isTrue);
      expect(OfferRepository.canWithdraw(countered, 'buyer1'), isFalse);
    });

    test('withdrawn is final: nothing can follow it', () {
      final withdrawn = offer(status: OfferStatus.withdrawn);
      expect(OfferRepository.canAct(withdrawn, 'seller1'), isFalse);
      expect(OfferRepository.canWithdraw(withdrawn, 'buyer1'), isFalse);
      for (final to in OfferStatus.values) {
        expect(Offer.canTransition(OfferStatus.withdrawn, to), isFalse);
      }
    });

    test('accepted and rejected bids cannot be withdrawn', () {
      expect(Offer.canTransition(OfferStatus.accepted, OfferStatus.withdrawn),
          isFalse);
      expect(Offer.canTransition(OfferStatus.rejected, OfferStatus.withdrawn),
          isFalse);
    });

    test('the update records a withdraw entry and keeps the amount', () {
      final update = OfferRepository.buildStatusUpdate(
          offer: offer(), byUserId: 'buyer1', to: OfferStatus.withdrawn);
      expect(update['status'], 'withdrawn');
      expect(update['amount'], 400);
    });
  });

  group('barter withdrawal', () {
    test('only the last proposer may withdraw a waiting proposal', () {
      expect(BarterRepository.canWithdraw(proposal(), 'prop1'), isTrue);
      expect(BarterRepository.canWithdraw(proposal(), 'owner1'), isFalse);
    });

    test('withdrawn is final', () {
      final withdrawn = proposal(status: BarterStatus.withdrawn);
      expect(BarterRepository.canAct(withdrawn, 'owner1'), isFalse);
      for (final to in BarterStatus.values) {
        expect(BarterProposal.canTransition(BarterStatus.withdrawn, to),
            isFalse);
      }
      expect(
          BarterRepository.buildStatusUpdate(
                  proposal: proposal(),
                  byUserId: 'prop1',
                  to: BarterStatus.withdrawn)['status'],
          'withdrawn');
    });
  });
}
