import 'package:cloud_firestore/cloud_firestore.dart';

enum BarterStatus { pending, accepted, rejected, countered, withdrawn }

/// A single item in a barter exchange (e.g. "50 kg manure").
class BarterItem {
  const BarterItem({required this.name, this.quantity, this.unit});

  final String name;
  final num? quantity;
  final String? unit;

  Map<String, dynamic> toMap() =>
      {'name': name, 'quantity': quantity, 'unit': unit};

  factory BarterItem.fromMap(Map<String, dynamic> map) => BarterItem(
        name: (map['name'] ?? '') as String,
        quantity: map['quantity'] as num?,
        unit: map['unit'] as String?,
      );

  @override
  String toString() =>
      [if (quantity != null) '$quantity', if (unit != null) unit, name]
          .join(' ');
}

/// One entry in a barter proposal's negotiation history (Sprint 3).
/// Counters carry a note describing the adjusted trade.
class BarterHistoryEntry {
  const BarterHistoryEntry({
    required this.byUserId,
    required this.action, // propose | counter | accept | reject
    this.note,
    this.at,
  });

  final String byUserId;
  final String action;
  final String? note;
  final DateTime? at;

  Map<String, dynamic> toMap() => {
        'byUserId': byUserId,
        'action': action,
        'note': note,
        'at': at == null ? Timestamp.now() : Timestamp.fromDate(at!),
      };

  factory BarterHistoryEntry.fromMap(Map<String, dynamic> map) =>
      BarterHistoryEntry(
        byUserId: (map['byUserId'] ?? '') as String,
        action: (map['action'] ?? 'propose') as String,
        note: map['note'] as String?,
        at: (map['at'] as Timestamp?)?.toDate(),
      );
}

/// A proposed goods-for-goods exchange between two parties.
/// ownerId (listing owner) is denormalized for security-rule checks;
/// listingTitle is denormalized so barter lists render read-free.
class BarterProposal {
  const BarterProposal({
    required this.barterId,
    required this.listingId,
    required this.proposerId,
    required this.ownerId,
    required this.offeredItems,
    required this.requestedItems,
    this.listingTitle = '',
    this.note,
    this.status = BarterStatus.pending,
    this.history = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String barterId;
  final String listingId;
  final String listingTitle; // denormalized
  final String proposerId;
  final String ownerId;
  final List<BarterItem> offeredItems;
  final List<BarterItem> requestedItems;
  final String? note;
  final BarterStatus status;
  final List<BarterHistoryEntry> history;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Same negotiation state machine as Offer.canTransition — unit-tested.
  static bool canTransition(BarterStatus from, BarterStatus to) {
    switch (from) {
      case BarterStatus.pending:
      case BarterStatus.countered:
        return to == BarterStatus.accepted ||
            to == BarterStatus.rejected ||
            to == BarterStatus.countered ||
            to == BarterStatus.withdrawn;
      case BarterStatus.accepted:
      case BarterStatus.rejected:
      case BarterStatus.withdrawn:
        return false; // terminal states (paper §3.5.3)
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'listingId': listingId,
      'listingTitle': listingTitle,
      'proposerId': proposerId,
      'ownerId': ownerId,
      'offeredItems': offeredItems.map((i) => i.toMap()).toList(),
      'requestedItems': requestedItems.map((i) => i.toMap()).toList(),
      'note': note,
      'status': status.name,
      'history': history.map((h) => h.toMap()).toList(),
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory BarterProposal.fromMap(String id, Map<String, dynamic> map) {
    List<BarterItem> items(dynamic raw) =>
        (raw as List?)
            ?.map((i) => BarterItem.fromMap(Map<String, dynamic>.from(i)))
            .toList() ??
        const [];

    return BarterProposal(
      barterId: id,
      listingId: (map['listingId'] ?? '') as String,
      listingTitle: (map['listingTitle'] ?? '') as String,
      proposerId: (map['proposerId'] ?? '') as String,
      ownerId: (map['ownerId'] ?? '') as String,
      offeredItems: items(map['offeredItems']),
      requestedItems: items(map['requestedItems']),
      note: map['note'] as String?,
      status: BarterStatus.values.firstWhere(
        (v) => v.name == (map['status'] ?? 'pending'),
        orElse: () => BarterStatus.pending,
      ),
      history: (map['history'] as List?)
              ?.map((h) =>
                  BarterHistoryEntry.fromMap(Map<String, dynamic>.from(h)))
              .toList() ??
          const [],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory BarterProposal.fromDoc(
          DocumentSnapshot<Map<String, dynamic>> doc) =>
      BarterProposal.fromMap(doc.id, doc.data() ?? const {});
}
