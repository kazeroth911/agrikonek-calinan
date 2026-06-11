import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/listing.dart';
import '../../../models/offer.dart';
import '../../../services/offer_repository.dart';
import '../../auth/providers/auth_providers.dart';

// ---- Repository -----------------------------------------------------------
final offerRepositoryProvider = Provider<OfferRepository>(
    (ref) => OfferRepository(ref.watch(firestoreProvider)));

// ---- Streams ---------------------------------------------------------------
/// Bids coming in across all of the signed-in seller's listings.
final incomingOffersProvider = StreamProvider<List<Offer>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(const <Offer>[]);
  return ref.watch(offerRepositoryProvider).watchOffersBySeller(user.uid);
});

/// Bids the signed-in buyer has sent.
final myOffersProvider = StreamProvider<List<Offer>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(const <Offer>[]);
  return ref.watch(offerRepositoryProvider).watchOffersByBuyer(user.uid);
});

/// One offer, live, for the detail screen.
final offerDetailProvider = StreamProvider.family<Offer?, String>(
    (ref, offerId) => ref.watch(offerRepositoryProvider).watchOffer(offerId));

/// All bids on one listing, for its seller (the listing detail screen's
/// owner view). Record argument gives the family value equality.
final listingOffersProvider = StreamProvider.family<List<Offer>,
        ({String listingId, String sellerId})>(
    (ref, args) => ref.watch(offerRepositoryProvider).watchOffersForListing(
        listingId: args.listingId, sellerId: args.sellerId));

/// How many incoming/sent items are waiting on MY move — drives the
/// bottom-nav badge so a farmer never misses an open negotiation.
final offersNeedingActionProvider = Provider<int>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return 0;
  final incoming = ref.watch(incomingOffersProvider).valueOrNull ?? [];
  final sent = ref.watch(myOffersProvider).valueOrNull ?? [];
  return {
    for (final o in [...incoming, ...sent])
      if (OfferRepository.canAct(o, uid)) o.offerId,
  }.length;
});

// ---- Controller -------------------------------------------------------------
/// Orchestrates each negotiation move: validated Firestore write first,
/// then the client-side notification document for the other party
/// (Cloud Functions deferred per approved plan).
final offerControllerProvider =
    Provider<OfferController>((ref) => OfferController(ref));

class OfferController {
  OfferController(this._ref);
  final Ref _ref;

  OfferRepository get _repo => _ref.read(offerRepositoryProvider);

  Map<String, dynamic> _payload(Offer offer, String action, num amount) => {
        'offerId': offer.offerId,
        'listingId': offer.listingId,
        'listingTitle': offer.listingTitle,
        'action': action,
        'amount': amount,
      };

  Future<void> _notify(String recipientId, Map<String, dynamic> payload) {
    return _ref
        .read(notificationRepositoryProvider)
        .notify(recipientId: recipientId, type: 'bid', payload: payload);
  }

  /// Returns the buyer's open offer on this listing if one exists —
  /// the bid sheet shows it and updates it instead of duplicating.
  Future<Offer?> findOpenOffer({
    required String listingId,
    required String buyerId,
  }) {
    return _repo.findOpenOffer(listingId: listingId, buyerId: buyerId);
  }

  Future<void> placeBid({
    required Listing listing,
    required String buyerId,
    required num amount,
    String? message,
  }) async {
    final offerId = await _repo.createOffer(
      listing: listing,
      buyerId: buyerId,
      amount: amount,
      message: message,
    );
    await _notify(listing.ownerId, {
      'offerId': offerId,
      'listingId': listing.listingId,
      'listingTitle': listing.title,
      'action': 'bid',
      'amount': amount,
    });
  }

  Future<void> accept({required Offer offer, required String byUserId}) async {
    await _repo.updateOfferStatus(
        offer: offer, byUserId: byUserId, to: OfferStatus.accepted);
    await _notify(_otherParty(offer, byUserId),
        _payload(offer, 'accept', offer.amount));
  }

  Future<void> reject({required Offer offer, required String byUserId}) async {
    await _repo.updateOfferStatus(
        offer: offer, byUserId: byUserId, to: OfferStatus.rejected);
    await _notify(_otherParty(offer, byUserId),
        _payload(offer, 'reject', offer.amount));
  }

  Future<void> counter({
    required Offer offer,
    required String byUserId,
    required num amount,
  }) async {
    await _repo.updateOfferStatus(
        offer: offer,
        byUserId: byUserId,
        to: OfferStatus.countered,
        counterAmount: amount);
    await _notify(
        _otherParty(offer, byUserId), _payload(offer, 'counter', amount));
  }

  String _otherParty(Offer offer, String byUserId) =>
      byUserId == offer.buyerId ? offer.sellerId : offer.buyerId;
}
