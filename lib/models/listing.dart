import 'package:cloud_firestore/cloud_firestore.dart';

enum ListingStatus { active, closed }

enum ListingMode { sale, barter, auction }

/// A product or farm resource posted for sale, barter, or auction.
/// ownerName / ownerBarangay are STRATEGICALLY DENORMALIZED from Profile
/// so the marketplace feed renders without an extra read per card
/// (free-tier read budget protection).
class Listing {
  const Listing({
    required this.listingId,
    required this.ownerId,
    required this.ownerName,
    required this.ownerBarangay,
    required this.title,
    required this.category,
    this.description = '',
    this.unit,
    this.price,
    this.modes = const [ListingMode.sale],
    this.photoUrls = const [],
    this.availableFrom,
    this.availableTo,
    this.status = ListingStatus.active,
    this.createdAt,
  });

  final String listingId;
  final String ownerId;
  final String ownerName; // denormalized
  final String ownerBarangay; // denormalized
  final String title;
  final String category;
  final String description;
  final String? unit; // kg, tray, sack...
  final num? price; // PHP; null when barter-only
  final List<ListingMode> modes;
  final List<String> photoUrls;
  final DateTime? availableFrom;
  final DateTime? availableTo;
  final ListingStatus status;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerBarangay': ownerBarangay,
      'title': title,
      'category': category,
      'description': description,
      'unit': unit,
      'price': price,
      'modes': modes.map((m) => m.name).toList(),
      'photoUrls': photoUrls,
      'availableFrom':
          availableFrom == null ? null : Timestamp.fromDate(availableFrom!),
      'availableTo':
          availableTo == null ? null : Timestamp.fromDate(availableTo!),
      'status': status.name,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
    };
  }

  factory Listing.fromMap(String id, Map<String, dynamic> map) {
    return Listing(
      listingId: id,
      ownerId: (map['ownerId'] ?? '') as String,
      ownerName: (map['ownerName'] ?? '') as String,
      ownerBarangay: (map['ownerBarangay'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      category: (map['category'] ?? 'Others') as String,
      description: (map['description'] ?? '') as String,
      unit: map['unit'] as String?,
      price: map['price'] as num?,
      modes: (map['modes'] as List?)
              ?.map((m) => ListingMode.values.firstWhere(
                    (v) => v.name == m,
                    orElse: () => ListingMode.sale,
                  ))
              .toList() ??
          const [ListingMode.sale],
      photoUrls: List<String>.from(map['photoUrls'] ?? const []),
      availableFrom: (map['availableFrom'] as Timestamp?)?.toDate(),
      availableTo: (map['availableTo'] as Timestamp?)?.toDate(),
      status: ListingStatus.values.firstWhere(
        (v) => v.name == (map['status'] ?? 'active'),
        orElse: () => ListingStatus.active,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory Listing.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Listing.fromMap(doc.id, doc.data() ?? const {});
}
