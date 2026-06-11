import 'package:cloud_firestore/cloud_firestore.dart';

enum BarterStatus { pending, accepted, rejected, countered }

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

/// A proposed goods-for-goods exchange between two parties.
/// ownerId (listing owner) is denormalized for security-rule checks.
class BarterProposal {
  const BarterProposal({
    required this.barterId,
    required this.listingId,
    required this.proposerId,
    required this.ownerId,
    required this.offeredItems,
    required this.requestedItems,
    this.note,
    this.status = BarterStatus.pending,
    this.createdAt,
  });

  final String barterId;
  final String listingId;
  final String proposerId;
  final String ownerId;
  final List<BarterItem> offeredItems;
  final List<BarterItem> requestedItems;
  final String? note;
  final BarterStatus status;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() {
    return {
      'listingId': listingId,
      'proposerId': proposerId,
      'ownerId': ownerId,
      'offeredItems': offeredItems.map((i) => i.toMap()).toList(),
      'requestedItems': requestedItems.map((i) => i.toMap()).toList(),
      'note': note,
      'status': status.name,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
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
      proposerId: (map['proposerId'] ?? '') as String,
      ownerId: (map['ownerId'] ?? '') as String,
      offeredItems: items(map['offeredItems']),
      requestedItems: items(map['requestedItems']),
      note: map['note'] as String?,
      status: BarterStatus.values.firstWhere(
        (v) => v.name == (map['status'] ?? 'pending'),
        orElse: () => BarterStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory BarterProposal.fromDoc(
          DocumentSnapshot<Map<String, dynamic>> doc) =>
      BarterProposal.fromMap(doc.id, doc.data() ?? const {});
}
