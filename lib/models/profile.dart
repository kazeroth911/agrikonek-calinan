import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/l10n/app_language.dart';

/// Root entity of the system (Figure 5 of the Capstone paper).
/// Created by the researcher-admin during field profiling.
class Profile {
  const Profile({
    required this.userId,
    required this.fullName,
    required this.roles,
    required this.barangay,
    this.phone,
    this.email,
    this.products = const [],
    this.barterWillingness = false,
    this.preferredTradeResources = const [],
    this.farmLocation,
    this.farmSizeNote,
    this.deviceType,
    this.dataPlan,
    this.photoUrls = const [],
    this.consentGiven = false,
    this.consentUrl,
    this.hidden = false,
    this.verificationLevel = 0,
    this.cooperativeId,
    this.claimedBy,
    this.claimedFrom,
    this.createdAt,
    this.updatedAt,
  });

  final String userId;
  final String fullName;
  final List<String> roles; // seller | buyer | trader | admin
  final String barangay;
  final String? phone;
  final String? email;

  /// What the farm produces (durian, eggs, manure, ...).
  final List<String> products;
  final bool barterWillingness;
  final List<String> preferredTradeResources;

  /// Stored only with explicit consent (RA 10173 commitment in §4.12).
  final GeoPoint? farmLocation;
  final String? farmSizeNote;

  final String? deviceType;
  final String? dataPlan;
  final List<String> photoUrls;

  final bool consentGiven;
  final String? consentUrl; // photo/scan of signed consent form

  /// Hidden by the farmer or an admin: the profile and its listings leave
  /// the marketplace, and others see "This profile is unavailable."
  /// Written only through ProfileRepository.setHidden, never by toMap,
  /// so saving other profile edits can never unhide it by accident.
  final bool hidden;

  /// Table 3.4 of the paper: 1 = the researchers met the person in
  /// Calinan; 2 = level 1 plus the cooperative confirmed membership, with
  /// the person's consent (C5). 0 = not recorded (older accounts).
  /// Set only by researcher-admins; the security rules stop owners from
  /// changing it.
  final int verificationLevel;

  /// The cooperative or association that confirmed membership. Saved only
  /// when the farmer agreed to cooperative confirmation (consent item C5).
  /// Set by researcher-admins; owners cannot change it.
  final String? cooperativeId;

  /// Claim status (paper §3.5.4). On a researcher-prepared profile,
  /// [claimedBy] is the phone-verified account that took it over; on that
  /// account's own profile, [claimedFrom] is the prepared profile it was
  /// copied from. Both are written only by the claim, never by toMap.
  final String? claimedBy;
  final String? claimedFrom;

  /// A prepared profile that has moved to a phone sign-in.
  bool get isClaimed => claimedBy != null;

  static const levelVisited = 1;
  static const levelCooperativeConfirmed = 2;

  /// What other users see, per Table 3.4, in the chosen language.
  String? verificationLabelFor(AppLanguage language) =>
      switch (verificationLevel) {
        levelVisited =>
          tr(language, 'Visited by researchers', 'Gibisita sa mga researcher'),
        levelCooperativeConfirmed => tr(
            language, 'Cooperative-confirmed', 'Gikumpirma sa kooperatiba'),
        _ => null,
      };
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAdmin => roles.contains('admin');

  Profile copyWith({
    String? fullName,
    List<String>? roles,
    String? barangay,
    String? phone,
    String? email,
    List<String>? products,
    bool? barterWillingness,
    List<String>? preferredTradeResources,
    GeoPoint? farmLocation,
    String? farmSizeNote,
    String? deviceType,
    String? dataPlan,
    List<String>? photoUrls,
    bool? consentGiven,
    String? consentUrl,
    String? cooperativeId,
  }) {
    return Profile(
      userId: userId,
      fullName: fullName ?? this.fullName,
      roles: roles ?? this.roles,
      barangay: barangay ?? this.barangay,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      products: products ?? this.products,
      barterWillingness: barterWillingness ?? this.barterWillingness,
      preferredTradeResources:
          preferredTradeResources ?? this.preferredTradeResources,
      farmLocation: farmLocation ?? this.farmLocation,
      farmSizeNote: farmSizeNote ?? this.farmSizeNote,
      deviceType: deviceType ?? this.deviceType,
      dataPlan: dataPlan ?? this.dataPlan,
      photoUrls: photoUrls ?? this.photoUrls,
      consentGiven: consentGiven ?? this.consentGiven,
      consentUrl: consentUrl ?? this.consentUrl,
      hidden: hidden,
      verificationLevel: verificationLevel,
      cooperativeId: cooperativeId ?? this.cooperativeId,
      claimedBy: claimedBy,
      claimedFrom: claimedFrom,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'roles': {
        for (final role in AppConstants.allRoles) role: roles.contains(role),
      },
      'barangay': barangay,
      'phone': phone,
      'email': email,
      'products': products,
      'barterWillingness': barterWillingness,
      'preferredTradeResources': preferredTradeResources,
      'farmLocation': farmLocation,
      'farmSizeNote': farmSizeNote,
      'deviceType': deviceType,
      'dataPlan': dataPlan,
      'photoUrls': photoUrls,
      'consentGiven': consentGiven,
      'consentUrl': consentUrl,
      'verificationLevel': verificationLevel,
      'cooperativeId': cooperativeId,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Profile.fromMap(String id, Map<String, dynamic> map) {
    return Profile(
      userId: id,
      fullName: (map['fullName'] ?? '') as String,
      roles: _rolesFromMap(map['roles']),
      barangay: (map['barangay'] ?? '') as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      products: List<String>.from(map['products'] ?? const []),
      barterWillingness: (map['barterWillingness'] ?? false) as bool,
      preferredTradeResources:
          List<String>.from(map['preferredTradeResources'] ?? const []),
      farmLocation: map['farmLocation'] as GeoPoint?,
      farmSizeNote: map['farmSizeNote'] as String?,
      deviceType: map['deviceType'] as String?,
      dataPlan: map['dataPlan'] as String?,
      photoUrls: List<String>.from(map['photoUrls'] ?? const []),
      consentGiven: (map['consentGiven'] ?? false) as bool,
      consentUrl: map['consentUrl'] as String?,
      hidden: (map['hidden'] ?? false) == true,
      verificationLevel: _levelFromMap(map['verificationLevel']),
      cooperativeId: map['cooperativeId'] as String?,
      claimedBy: map['claimedBy'] as String?,
      claimedFrom: map['claimedFrom'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory Profile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Profile.fromMap(doc.id, doc.data() ?? const {});

  static int _levelFromMap(Object? raw) {
    if (raw is num) {
      final level = raw.toInt();
      if (level == levelVisited || level == levelCooperativeConfirmed) {
        return level;
      }
    }
    return 0;
  }

  /// `roles` is stored as a `{role: bool}` map (e.g. `{admin: true,
  /// seller: false}`); only roles set to `true` are active. Older
  /// documents may still store `roles` as a `List<String>` of active
  /// role names — both shapes are accepted defensively.
  static List<String> _rolesFromMap(dynamic raw) {
    if (raw is Map) {
      return raw.entries
          .where((e) => e.value == true)
          .map((e) => e.key.toString())
          .toList();
    }
    if (raw is Iterable) {
      return List<String>.from(raw);
    }
    return const [];
  }
}
