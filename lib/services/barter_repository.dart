import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/barter_proposal.dart';
import '../models/listing.dart';

/// All Firestore access for the barterProposals collection. Mirrors
/// OfferRepository: equality-only queries (no composite indexes, provably
/// safe under the security rules) and a pure, unit-tested transition gate.
class BarterRepository {
  BarterRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(AppConstants.colBarterProposals);

  // ---- pure business logic (unit-tested, no Firestore needed) ----------

  /// Whose turn is it? Same convention as offers: the party who did not
  /// move last may act, and a fresh proposal is the owner's move.
  static bool canAct(BarterProposal proposal, String uid) {
    if (uid != proposal.proposerId && uid != proposal.ownerId) return false;
    if (!_isOpen(proposal.status)) return false;
    return lastActor(proposal) != uid;
  }

  static bool _isOpen(BarterStatus s) =>
      s == BarterStatus.pending || s == BarterStatus.countered;

  /// Who made the last move. A fresh proposal is the proposer's.
  static String lastActor(BarterProposal proposal) => proposal.history.isEmpty
      ? proposal.proposerId
      : proposal.history.last.byUserId;

  /// The party who made the last proposal may withdraw it while it is
  /// waiting for the other party (paper §3.5.3).
  static bool canWithdraw(BarterProposal proposal, String uid) {
    if (uid != proposal.proposerId && uid != proposal.ownerId) return false;
    return _isOpen(proposal.status) && lastActor(proposal) == uid;
  }

  /// Update map for a status change, gated by the BarterProposal state
  /// machine. Counters must carry a note describing the adjusted trade.
  /// History is appended via arrayUnion — append-only by construction.
  static Map<String, dynamic> buildStatusUpdate({
    required BarterProposal proposal,
    required String byUserId,
    required BarterStatus to,
    String? counterNote,
  }) {
    if (!BarterProposal.canTransition(proposal.status, to)) {
      throw StateError(
          'Barter cannot move from ${proposal.status.name} to ${to.name}.');
    }
    if (to == BarterStatus.countered &&
        (counterNote == null || counterNote.trim().isEmpty)) {
      throw StateError('A counter needs a note describing the new trade.');
    }

    final action = switch (to) {
      BarterStatus.accepted => 'accept',
      BarterStatus.rejected => 'reject',
      BarterStatus.countered => 'counter',
      BarterStatus.withdrawn => 'withdraw',
      BarterStatus.pending => 'propose',
    };

    return {
      'status': to.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'history': FieldValue.arrayUnion([
        BarterHistoryEntry(
          byUserId: byUserId,
          action: action,
          note: to == BarterStatus.countered ? counterNote!.trim() : null,
        ).toMap(),
      ]),
    };
  }

  // ---- writes -----------------------------------------------------------

  Future<String> createBarterProposal({
    required Listing listing,
    required String proposerId,
    required List<BarterItem> offeredItems,
    required List<BarterItem> requestedItems,
    String? note,
  }) async {
    final proposal = BarterProposal(
      barterId: '', // assigned by Firestore
      listingId: listing.listingId,
      listingTitle: listing.title, // denormalized for barter lists
      proposerId: proposerId,
      ownerId: listing.ownerId, // denormalized for security rules
      offeredItems: offeredItems,
      requestedItems: requestedItems,
      note: (note == null || note.trim().isEmpty) ? null : note.trim(),
      history: [
        BarterHistoryEntry(byUserId: proposerId, action: 'propose'),
      ],
    );
    final doc = await _col.add(proposal.toMap());
    return doc.id;
  }

  Future<void> updateBarterStatus({
    required BarterProposal proposal,
    required String byUserId,
    required BarterStatus to,
    String? counterNote,
  }) {
    return _col.doc(proposal.barterId).update(buildStatusUpdate(
          proposal: proposal,
          byUserId: byUserId,
          to: to,
          counterNote: counterNote,
        ));
  }

  // ---- streams ----------------------------------------------------------

  Stream<BarterProposal?> watchBarterProposal(String barterId) {
    return _col.doc(barterId).snapshots().map(
        (doc) => doc.exists ? BarterProposal.fromDoc(doc) : null);
  }

  /// Proposals on one listing, for its owner (ownerId filter keeps the
  /// query provably readable under the rules).
  Stream<List<BarterProposal>> watchBarterProposalsForListing({
    required String listingId,
    required String ownerId,
  }) {
    return _col
        .where('ownerId', isEqualTo: ownerId)
        .where('listingId', isEqualTo: listingId)
        .snapshots()
        .map(_sorted);
  }

  Stream<List<BarterProposal>> watchBarterProposalsByProposer(
      String proposerId) {
    return _col
        .where('proposerId', isEqualTo: proposerId)
        .snapshots()
        .map(_sorted);
  }

  Stream<List<BarterProposal>> watchBarterProposalsByOwner(String ownerId) {
    return _col
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map(_sorted);
  }

  List<BarterProposal> _sorted(QuerySnapshot<Map<String, dynamic>> snap) {
    final proposals = snap.docs.map(BarterProposal.fromDoc).toList();
    proposals.sort((a, b) => (b.updatedAt ?? b.createdAt ?? DateTime(0))
        .compareTo(a.updatedAt ?? a.createdAt ?? DateTime(0)));
    return proposals;
  }
}
