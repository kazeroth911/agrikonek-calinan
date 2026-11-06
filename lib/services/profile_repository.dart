import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/profile.dart';

/// All Firestore access for the profiles collection lives here.
/// Screens and providers never query Firestore directly — clean
/// separation of UI, business logic, and data (paper §4.6).
class ProfileRepository {
  ProfileRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(AppConstants.colProfiles);

  /// Stream a single profile (used for the signed-in user).
  Stream<Profile?> watchProfile(String uid) {
    return _col.doc(uid).snapshots().map(
        (doc) => doc.exists ? Profile.fromDoc(doc) : null);
  }

  Future<Profile?> getProfile(String uid) async {
    final doc = await _col.doc(uid).get();
    return doc.exists ? Profile.fromDoc(doc) : null;
  }

  /// Creates the profile document at the farmer's auth uid.
  Future<void> createProfile(Profile profile) {
    return _col.doc(profile.userId).set(profile.toMap());
  }

  Future<void> updateProfile(Profile profile) {
    return _col.doc(profile.userId).set(
          profile.toMap(),
          SetOptions(merge: true),
        );
  }

  /// Saves a researcher-prepared profile as HIDDEN (paper §3.5.4 and
  /// Table 3.14): the profile and the hidden-ID entry are written in one
  /// batch, so it never appears to other users, not even for a moment.
  Future<void> createPreparedProfile(Profile profile,
      {required String byUid}) {
    final batch = _db.batch();
    batch.set(_col.doc(profile.userId), {
      ...profile.toMap(),
      'hidden': true,
      'hiddenAt': FieldValue.serverTimestamp(),
    });
    batch.set(_db.collection(AppConstants.colHiddenProfiles).doc(profile.userId), {
      'hiddenAt': FieldValue.serverTimestamp(),
      'hiddenBy': byUid,
    });
    return batch.commit();
  }

  // ---- Profile claiming (paper §3.5.4) ------------------------------------
  //
  // A farmer who joins the separately consented testing phase signs in
  // with phone verification. The app then finds the researcher-prepared
  // profile with the same verified number and copies it to the new
  // account. The paper's design does this in a Cloud Function; here the
  // security rules check the same conditions instead, so it works on the
  // no-cost Spark plan:
  //  - the prepared profile's phone equals the verified phone number;
  //  - it has not been claimed and is not a researcher account;
  //  - the copy is identical except for the claim fields;
  //  - the copy and the "claimed" mark are written together.

  /// Unclaimed prepared profiles for this verified [e164Phone]. Usually
  /// one, but family members may share a phone, so the farmer picks.
  Future<List<DocumentSnapshot<Map<String, dynamic>>>> findClaimableProfiles({
    required String e164Phone,
    required String uid,
  }) async {
    final snap =
        await _col.where('phone', isEqualTo: e164Phone).limit(10).get();
    return [
      for (final doc in snap.docs)
        if (doc.id != uid &&
            doc.data()['claimedBy'] == null &&
            !(doc.data()['roles'] is Map &&
                (doc.data()['roles'] as Map)['admin'] == true))
          doc,
    ];
  }

  /// Copies the prepared profile to [uid] and marks the original claimed,
  /// in one batch. A hidden profile stays hidden: the farmer (or a
  /// researcher) shows it when the testing-phase consent allows.
  Future<void> claimProfile({
    required DocumentSnapshot<Map<String, dynamic>> prepared,
    required String uid,
  }) {
    final data = prepared.data();
    if (data == null) throw StateError('That profile no longer exists.');
    final batch = _db.batch();
    batch.set(_col.doc(uid), {
      ...data,
      'claimedFrom': prepared.id,
      'claimedAt': FieldValue.serverTimestamp(),
    });
    batch.update(prepared.reference, {
      'claimedBy': uid,
      'claimedAt': FieldValue.serverTimestamp(),
    });
    if (data['hidden'] == true) {
      batch.set(_db.collection(AppConstants.colHiddenProfiles).doc(uid), {
        'hiddenAt': FieldValue.serverTimestamp(),
        'hiddenBy': uid,
      });
    }
    return batch.commit();
  }

  /// Researcher-admin records which cooperative confirmed a farmer
  /// (only where the farmer agreed to cooperative confirmation, C5).
  Future<void> setCooperative(String uid, String? cooperativeId) {
    return _col.doc(uid).update({'cooperativeId': cooperativeId});
  }

  /// Researcher-admin changes a profile's verification level (Table 3.4).
  Future<void> setVerificationLevel(String uid, int level) {
    return _col.doc(uid).update({'verificationLevel': level});
  }

  /// Hides or unhides a profile in one batch: the flag on the profile
  /// and the entry in the public list of hidden IDs always agree.
  Future<void> setHidden({
    required String uid,
    required bool hidden,
    required String byUid,
  }) {
    final batch = _db.batch();
    final marker = _db.collection(AppConstants.colHiddenProfiles).doc(uid);
    batch.update(_col.doc(uid), {
      'hidden': hidden,
      'hiddenAt': hidden ? FieldValue.serverTimestamp() : null,
    });
    if (hidden) {
      batch.set(marker, {
        'hiddenAt': FieldValue.serverTimestamp(),
        'hiddenBy': byUid,
      });
    } else {
      batch.delete(marker);
    }
    return batch.commit();
  }

  /// IDs of every hidden profile, live.
  Stream<Set<String>> watchHiddenIds() {
    return _db
        .collection(AppConstants.colHiddenProfiles)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  /// Admin list view — newest first. Ordered by createdAt so the
  /// researcher sees their most recent field entries on top.
  Stream<List<Profile>> watchAllProfiles({String? barangay}) {
    Query<Map<String, dynamic>> q =
        _col.orderBy('createdAt', descending: true);
    if (barangay != null && barangay.isNotEmpty) {
      q = q.where('barangay', isEqualTo: barangay);
    }
    return q.snapshots().map(
        (snap) => snap.docs.map(Profile.fromDoc).toList());
  }
}
