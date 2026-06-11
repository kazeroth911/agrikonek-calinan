import 'package:agrikonek_calinan/models/barter_proposal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BarterProposal state machine', () {
    test('pending can be accepted, rejected, or countered', () {
      expect(
          BarterProposal.canTransition(
              BarterStatus.pending, BarterStatus.accepted),
          isTrue);
      expect(
          BarterProposal.canTransition(
              BarterStatus.pending, BarterStatus.rejected),
          isTrue);
      expect(
          BarterProposal.canTransition(
              BarterStatus.pending, BarterStatus.countered),
          isTrue);
    });

    test('countered can continue negotiating', () {
      expect(
          BarterProposal.canTransition(
              BarterStatus.countered, BarterStatus.accepted),
          isTrue);
      expect(
          BarterProposal.canTransition(
              BarterStatus.countered, BarterStatus.countered),
          isTrue);
      expect(
          BarterProposal.canTransition(
              BarterStatus.countered, BarterStatus.rejected),
          isTrue);
    });

    test('accepted and rejected are terminal', () {
      for (final to in BarterStatus.values) {
        expect(BarterProposal.canTransition(BarterStatus.accepted, to),
            isFalse);
        expect(BarterProposal.canTransition(BarterStatus.rejected, to),
            isFalse);
      }
    });

    test('nothing can move back to pending', () {
      for (final from in BarterStatus.values) {
        expect(
            BarterProposal.canTransition(from, BarterStatus.pending), isFalse);
      }
    });
  });

  group('BarterProposal model', () {
    test('fromMap round-trips items and history', () {
      final proposal = BarterProposal.fromMap('bar1', {
        'listingId': 'lst1',
        'listingTitle': 'Native eggs',
        'proposerId': 'p1',
        'ownerId': 'o1',
        'offeredItems': [
          {'name': 'compost', 'quantity': 2, 'unit': 'sack'},
        ],
        'requestedItems': [
          {'name': 'Native eggs', 'quantity': 3, 'unit': 'tray'},
        ],
        'note': 'Can deliver',
        'status': 'countered',
        'history': [
          {'byUserId': 'p1', 'action': 'propose'},
          {'byUserId': 'o1', 'action': 'counter', 'note': '3 sacks please'},
        ],
      });

      expect(proposal.listingTitle, 'Native eggs');
      expect(proposal.offeredItems.single.toString(), '2 sack compost');
      expect(proposal.requestedItems.single.name, 'Native eggs');
      expect(proposal.status, BarterStatus.countered);
      expect(proposal.history, hasLength(2));
      expect(proposal.history.last.note, '3 sacks please');

      final map = proposal.toMap();
      expect(map['ownerId'], 'o1');
      expect((map['offeredItems'] as List).single['name'], 'compost');
      expect((map['history'] as List), hasLength(2));
    });

    test('handles missing/empty map defensively', () {
      final proposal = BarterProposal.fromMap('x', {});
      expect(proposal.offeredItems, isEmpty);
      expect(proposal.requestedItems, isEmpty);
      expect(proposal.status, BarterStatus.pending);
      expect(proposal.history, isEmpty);
    });

    test('BarterItem.toString formats quantity unit name', () {
      expect(
          const BarterItem(name: 'manure', quantity: 50, unit: 'kg')
              .toString(),
          '50 kg manure');
      expect(const BarterItem(name: 'carabao').toString(), 'carabao');
    });
  });
}
