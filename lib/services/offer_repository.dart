import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/listing.dart';
import '../models/offer.dart';

/// All Firestore access for the offers (bids) collection.
///
/// QUERY STRATEGY: every list query uses equality filters only (buyerId /
/// sellerId / listingId), which Firestore serves via index merging — no
/// composite indexes to maintain. The filters also make each query
/// provably safe under the security rules (a query must guarantee the
/// reader is the buyer or seller). Sorting happens client-side.
class OfferRepository {
  OfferRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(AppConstants.colOffers);

  // ---- pure business logic (unit-tested, no Firestore needed) ----------

  /// Whose turn is it? A party may act (accept/reject/counter) when the
  /// offer is still negotiable AND they were not the last one to move —
  /// a fresh bid (empty-history fallback) is the seller's move.
  static bool canAct(Offer offer, String uid) {
    if (uid != offer.buyerId && uid != offer.sellerId) return false;
    if (offer.status == OfferStatus.accepted ||
        offer.status == OfferStatus.rejected) {
      return false;
    }
    final lastActor =
        offer.history.isEmpty ? offer.buyerId : offer.history.last.byUserId;
    return lastActor != uid;
  }

  /// Builds the Firestore update map for a status change, gated by the
  /// Offer.canTransition state machine. Throws StateError on an illegal
  /// transition so a stale UI can never corrupt a terminal offer.
  /// The history entry is appended via arrayUnion — append-only by
  /// construction, existing entries are never touched.
  static Map<String, dynamic> buildStatusUpdate({
    required Offer offer,
    required String byUserId,
    required OfferStatus to,
    num? counterAmount,
  }) {
    if (!Offer.canTransition(offer.status, to)) {
      throw StateError(
          'Offer cannot move from ${offer.status.name} to ${to.name}.');
    }
    if (to == OfferStatus.countered &&
        (counterAmount == null || counterAmount <= 0)) {
      throw StateError('A counter needs a valid amount.');
    }

    final action = switch (to) {
      OfferStatus.accepted => 'accept',
      OfferStatus.rejected => 'reject',
      OfferStatus.countered => 'counter',
      OfferStatus.pending => 'bid',
    };
    final amount =
        to == OfferStatus.countered ? counterAmount! : offer.amount;

    return {
      'status': to.name,
      'amount': amount,
      'updatedAt': FieldValue.serverTimestamp(),
      'history': FieldValue.arrayUnion([
        OfferHistoryEntry(byUserId: byUserId, amount: amount, action: action)
            .toMap(),
      ]),
    };
  }

  // ---- writes -----------------------------------------------------------

  /// Buyer places a bid. The opening bid is history entry #1.
  Future<String> createOffer({
    required Listing listing,
    required String buyerId,
    required num amount,
    String? message,
  }) async {
    final offer = Offer(
      offerId: '', // assigned by Firestore
      listingId: listing.listingId,
      listingTitle: listing.title, // denormalized for offer lists
      buyerId: buyerId,
      sellerId: listing.ownerId, // denormalized for security rules
      amount: amount,
      message: (message == null || message.trim().isEmpty)
          ? null
          : message.trim(),
      history: [
        OfferHistoryEntry(byUserId: buyerId, amount: amount, action: 'bid'),
      ],
    );
    final doc = await _col.add(offer.toMap());
    return doc.id;
  }

  /// Accept / reject / counter — validated by buildStatusUpdate above.
  Future<void> updateOfferStatus({
    required Offer offer,
    required String byUserId,
    required OfferStatus to,
    num? counterAmount,
  }) {
    return _col.doc(offer.offerId).update(buildStatusUpdate(
          offer: offer,
          byUserId: byUserId,
          to: to,
          counterAmount: counterAmount,
        ));
  }

  // ---- streams ----------------------------------------------------------

  Stream<Offer?> watchOffer(String offerId) {
    return _col.doc(offerId).snapshots().map(
        (doc) => doc.exists ? Offer.fromDoc(doc) : null);
  }

  /// All bids on one listing, for its seller. The sellerId filter is
  /// required: it is what makes the query provably readable under the
  /// security rules.
  Stream<List<Offer>> watchOffersForListing({
    required String listingId,
    required String sellerId,
  }) {
    return _col
        .where('sellerId', isEqualTo: sellerId)
        .where('listingId', isEqualTo: listingId)
        .snapshots()
        .map(_sorted);
  }

  /// Bids the buyer has sent, newest activity first.
  Stream<List<Offer>> watchOffersByBuyer(String buyerId) {
    return _col
        .where('buyerId', isEqualTo: buyerId)
        .snapshots()
        .map(_sorted);
  }

  /// Bids coming in across all of a seller's listings.
  Stream<List<Offer>> watchOffersBySeller(String sellerId) {
    return _col
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map(_sorted);
  }

  /// The buyer's still-negotiable offer on a listing, if any — lets the
  /// bid sheet update the existing offer instead of creating a duplicate.
  Future<Offer?> findOpenOffer({
    required String listingId,
    required String buyerId,
  }) async {
    final snap = await _col
        .where('buyerId', isEqualTo: buyerId)
        .where('listingId', isEqualTo: listingId)
        .get();
    final open = snap.docs.map(Offer.fromDoc).where((o) =>
        o.status == OfferStatus.pending || o.status == OfferStatus.countered);
    return open.isEmpty ? null : open.first;
  }

  List<Offer> _sorted(QuerySnapshot<Map<String, dynamic>> snap) {
    final offers = snap.docs.map(Offer.fromDoc).toList();
    offers.sort((a, b) => (b.updatedAt ?? b.createdAt ?? DateTime(0))
        .compareTo(a.updatedAt ?? a.createdAt ?? DateTime(0)));
    return offers;
  }
}
