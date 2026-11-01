import 'package:cloud_firestore/cloud_firestore.dart';

/// A cooperative or farmers' association that, with a member's consent
/// (C5), confirms that member's profile (Table 3.4, level 2). Managed by
/// researcher-admins. Cooperatives receive no individual responses and are
/// never told who declined; this record only names the organization.
class Cooperative {
  const Cooperative({
    required this.cooperativeId,
    required this.name,
    this.barangay,
    this.createdAt,
  });

  static const maxNameLength = 120;

  final String cooperativeId;
  final String name;
  final String? barangay;
  final DateTime? createdAt;

  /// Fields written on create. The security rules accept exactly these.
  Map<String, dynamic> toMap() => {
        'name': name.trim(),
        'barangay': barangay,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory Cooperative.fromMap(String id, Map<String, dynamic> map) {
    return Cooperative(
      cooperativeId: id,
      name: (map['name'] ?? '') as String,
      barangay: map['barangay'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
