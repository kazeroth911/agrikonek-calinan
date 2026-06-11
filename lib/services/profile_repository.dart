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
