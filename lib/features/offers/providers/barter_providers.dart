import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/barter_proposal.dart';
import '../../../models/listing.dart';
import '../../../services/barter_repository.dart';
import '../../auth/providers/auth_providers.dart';

// ---- Repository -----------------------------------------------------------
final barterRepositoryProvider = Provider<BarterRepository>(
    (ref) => BarterRepository(ref.watch(firestoreProvider)));

// ---- Streams ---------------------------------------------------------------
/// Proposals arriving on the signed-in owner's listings.
final incomingBarterProvider = StreamProvider<List<BarterProposal>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(const <BarterProposal>[]);
  return ref
      .watch(barterRepositoryProvider)
      .watchBarterProposalsByOwner(user.uid);
});

/// Proposals the signed-in user has sent.
final myBarterProposalsProvider = StreamProvider<List<BarterProposal>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(const <BarterProposal>[]);
  return ref
      .watch(barterRepositoryProvider)
      .watchBarterProposalsByProposer(user.uid);
});

/// One proposal, live, for the detail screen.
final barterDetailProvider =
    StreamProvider.family<BarterProposal?, String>((ref, barterId) {
  // Re-subscribe on auth change: a proposer↔owner account switch must not
  // serve the previous user's cached permission-denied for this proposal.
  ref.watch(authStateProvider);
  return ref.watch(barterRepositoryProvider).watchBarterProposal(barterId);
});

/// All proposals on one listing, for its owner (the listing detail
/// screen's owner view). Record argument gives the family value equality.
final listingBartersProvider = StreamProvider.family<List<BarterProposal>,
    ({String listingId, String ownerId})>((ref, args) {
  ref.watch(authStateProvider);
  return ref
      .watch(barterRepositoryProvider)
      .watchBarterProposalsForListing(
          listingId: args.listingId, ownerId: args.ownerId);
});

/// Barter items waiting on MY move — drives the bottom-nav badge.
final bartersNeedingActionProvider = Provider<int>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return 0;
  final incoming = ref.watch(incomingBarterProvider).valueOrNull ?? [];
  final sent = ref.watch(myBarterProposalsProvider).valueOrNull ?? [];
  return {
    for (final b in [...incoming, ...sent])
      if (BarterRepository.canAct(b, uid)) b.barterId,
  }.length;
});

// ---- Controller -------------------------------------------------------------
/// Validated write first, then the client-side notification document
/// for the other party. The sendPushOnNotification Cloud Function turns
/// it into a phone push.
final barterControllerProvider =
    Provider<BarterController>((ref) => BarterController(ref));

class BarterController {
  BarterController(this._ref);
  final Ref _ref;

  BarterRepository get _repo => _ref.read(barterRepositoryProvider);

  Future<void> _notify(String recipientId, String senderId,
      BarterProposal proposal, String action, String barterId) {
    return _ref.read(notificationRepositoryProvider).notify(
      recipientId: recipientId,
      senderId: senderId,
      type: 'barter',
      payload: {
        'barterId': barterId,
        'listingId': proposal.listingId,
        'listingTitle': proposal.listingTitle,
        'action': action,
      },
    );
  }

  Future<void> propose({
    required Listing listing,
    required String proposerId,
    required List<BarterItem> offeredItems,
    required List<BarterItem> requestedItems,
    String? note,
  }) async {
    final barterId = await _repo.createBarterProposal(
      listing: listing,
      proposerId: proposerId,
      offeredItems: offeredItems,
      requestedItems: requestedItems,
      note: note,
    );
    await _ref.read(notificationRepositoryProvider).notify(
      recipientId: listing.ownerId,
      senderId: proposerId,
      type: 'barter',
      payload: {
        'barterId': barterId,
        'listingId': listing.listingId,
        'listingTitle': listing.title,
        'action': 'propose',
      },
    );
  }

  Future<void> accept(
      {required BarterProposal proposal, required String byUserId}) async {
    await _repo.updateBarterStatus(
        proposal: proposal, byUserId: byUserId, to: BarterStatus.accepted);
    await _notify(_otherParty(proposal, byUserId), byUserId, proposal, 'accept',
        proposal.barterId);
  }

  Future<void> reject(
      {required BarterProposal proposal, required String byUserId}) async {
    await _repo.updateBarterStatus(
        proposal: proposal, byUserId: byUserId, to: BarterStatus.rejected);
    await _notify(_otherParty(proposal, byUserId), byUserId, proposal, 'reject',
        proposal.barterId);
  }

  Future<void> counter({
    required BarterProposal proposal,
    required String byUserId,
    required String note,
  }) async {
    await _repo.updateBarterStatus(
        proposal: proposal,
        byUserId: byUserId,
        to: BarterStatus.countered,
        counterNote: note);
    await _notify(_otherParty(proposal, byUserId), byUserId, proposal, 'counter',
        proposal.barterId);
  }

  String _otherParty(BarterProposal proposal, String byUserId) =>
      byUserId == proposal.proposerId ? proposal.ownerId : proposal.proposerId;
}
