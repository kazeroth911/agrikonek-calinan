import 'package:cloud_firestore/cloud_firestore.dart';

enum OfferStatus { pending, accepted, rejected, countered }

/// One entry in an offer's negotiation history.
class OfferHistoryEntry {
  const OfferHistoryEntry({
    required this.byUserId,
    required this.amount,
    required this.action, // bid | counter | accept | reject
    this.at,
  });

  final String byUserId;
  final num amount;
  final String action;
  final DateTime? at;

  Map<String, dynamic> toMap() => {
        'byUserId': byUserId,
        'amount': amount,
        'action': action,
        'at': at == null ? Timestamp.now() : Timestamp.fromDate(at!),
      };

  factory OfferHistoryEntry.fromMap(Map<String, dynamic> map) =>
      OfferHistoryEntry(
        byUserId: (map['byUserId'] ?? '') as String,
        amount: (map['amount'] ?? 0) as num,
        action: (map['action'] ?? 'bid') as String,
        at: (map['at'] as Timestamp?)?.toDate(),
      );
}

/// A price bid on a Listing with full negotiation history.
/// sellerId is denormalized so security rules can authorize the
/// listing owner without a cross-document get().
class Offer {
  const Offer({
    required this.offerId,
    required this.listingId,
    required this.buyerId,
    required this.sellerId,
    required this.amount,
    this.currency = 'PHP',
    this.message,
    this.status = OfferStatus.pending,
    this.history = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String offerId;
  final String listingId;
  final String buyerId;
  final String sellerId;
  final num amount;
  final String currency;
  final String? message;
  final OfferStatus status;
  final List<OfferHistoryEntry> history;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Allowed state machine for offer transitions — unit-tested.
  static bool canTransition(OfferStatus from, OfferStatus to) {
    switch (from) {
      case OfferStatus.pending:
      case OfferStatus.countered:
        return to == OfferStatus.accepted ||
            to == OfferStatus.rejected ||
            to == OfferStatus.countered;
      case OfferStatus.accepted:
      case OfferStatus.rejected:
        return false; // terminal states
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'listingId': listingId,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'amount': amount,
      'currency': currency,
      'message': message,
      'status': status.name,
      'history': history.map((h) => h.toMap()).toList(),
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Offer.fromMap(String id, Map<String, dynamic> map) {
    return Offer(
      offerId: id,
      listingId: (map['listingId'] ?? '') as String,
      buyerId: (map['buyerId'] ?? '') as String,
      sellerId: (map['sellerId'] ?? '') as String,
      amount: (map['amount'] ?? 0) as num,
      currency: (map['currency'] ?? 'PHP') as String,
      message: map['message'] as String?,
      status: OfferStatus.values.firstWhere(
        (v) => v.name == (map['status'] ?? 'pending'),
        orElse: () => OfferStatus.pending,
      ),
      history: (map['history'] as List?)
              ?.map((h) =>
                  OfferHistoryEntry.fromMap(Map<String, dynamic>.from(h)))
              .toList() ??
          const [],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory Offer.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Offer.fromMap(doc.id, doc.data() ?? const {});
}
