import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/listing.dart';

/// All Firestore access for the listings collection (paper §4.6 layering:
/// screens and providers never query Firestore directly).
///
/// QUERY STRATEGY (free-tier + solo-dev): the feed is one capped query
/// ordered by createdAt only — that uses Firestore's automatic single-field
/// index, so no composite indexes to create or maintain. Status, category,
/// and keyword filters run client-side; the pilot cohort is small enough
/// (~dozens of active listings) that this stays well inside read budget.
class ListingRepository {
  ListingRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(AppConstants.colListings);

  /// Newest-first marketplace feed. Closed listings are filtered out
  /// here; category filtering happens in the provider layer so one
  /// stream subscription serves every chip selection.
  Stream<List<Listing>> watchFeed() {
    return _col
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.feedQueryLimit)
        .snapshots()
        .map((snap) => snap.docs
            .map(Listing.fromDoc)
            .where((l) => l.status == ListingStatus.active)
            .toList());
  }

  /// One listing, live — keeps the detail screen current if the owner
  /// edits or closes it while a buyer is looking.
  Stream<Listing?> watchListing(String listingId) {
    return _col.doc(listingId).snapshots().map(
        (doc) => doc.exists ? Listing.fromDoc(doc) : null);
  }

  /// The signed-in farmer's own listings, any status, newest first.
  /// Equality-only filter — still no composite index needed.
  Stream<List<Listing>> watchListingsByOwner(String ownerId) {
    return _col.where('ownerId', isEqualTo: ownerId).snapshots().map((snap) {
      final listings = snap.docs.map(Listing.fromDoc).toList();
      listings.sort((a, b) => (b.createdAt ?? DateTime(0))
          .compareTo(a.createdAt ?? DateTime(0)));
      return listings;
    });
  }

  /// Returns the new document id.
  Future<String> createListing(Listing listing) async {
    final doc = await _col.add(listing.toMap());
    return doc.id;
  }

  Future<void> updateListing(String listingId, Map<String, dynamic> fields) {
    return _col.doc(listingId).update(fields);
  }

  /// Soft close — the listing disappears from the feed but its history
  /// stays intact for Sprint 3 offers that reference it.
  Future<void> closeListing(String listingId) {
    return updateListing(listingId, {'status': ListingStatus.closed.name});
  }

  Future<void> deleteListing(String listingId) {
    return _col.doc(listingId).delete();
  }

  /// Pure keyword filter over the streamed feed — matches title,
  /// description, category, owner name, and barangay. Pure Dart so it is
  /// unit-testable per the 70%-coverage commitment on business logic.
  static List<Listing> filterByKeyword(List<Listing> listings, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return listings;
    return listings.where((l) {
      return l.title.toLowerCase().contains(q) ||
          l.description.toLowerCase().contains(q) ||
          l.category.toLowerCase().contains(q) ||
          l.ownerName.toLowerCase().contains(q) ||
          l.ownerBarangay.toLowerCase().contains(q);
    }).toList();
  }
}
