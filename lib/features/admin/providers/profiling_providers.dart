import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/profile.dart';
import '../../../services/admin_account_service.dart';
import '../../auth/providers/auth_providers.dart';

/// Stream of all profiles for the admin list (optionally filtered later).
final allProfilesProvider = StreamProvider<List<Profile>>(
    (ref) => ref.watch(profileRepositoryProvider).watchAllProfiles());

/// Result handed back to the form so the researcher can print/write
/// the credential slip for the farmer (paper §3.4 workflow 1).
class ProfilingResult {
  const ProfilingResult({
    required this.uid,
    required this.email,
    required this.starterPassword,
  });
  final String uid;
  final String email;
  final String starterPassword;
}

/// Orchestrates the full profiling save:
/// 1. create auth account on the secondary app (admin stays signed in)
/// 2. upload farm photos to Cloud Storage
/// 3. write the Profile document at the new uid
final profilingControllerProvider =
    Provider<ProfilingController>((ref) => ProfilingController(ref));

class ProfilingController {
  ProfilingController(this._ref);
  final Ref _ref;

  Future<ProfilingResult> saveNewFarmer({
    required Profile draft,
    required String email,
    String? starterPassword,
    List<File> photos = const [],
    GeoPoint? farmLocation,
  }) async {
    final accounts = _ref.read(adminAccountServiceProvider);
    final repo = _ref.read(profileRepositoryProvider);

    final password =
        starterPassword ?? AdminAccountService.generateStarterPassword();

    // 1. Auth account (secondary app keeps the admin session alive).
    final uid = await accounts.createFarmerAuthAccount(
      email: email,
      password: password,
    );

    // 2. Photos — best-effort: an empty result means Storage is
    // unavailable (Spark tier / offline) and the profile saves photo-less.
    final photoUrls = await _ref
        .read(storageServiceProvider)
        .uploadProfilePhotos(uid: uid, files: photos);

    // 3. Profile document keyed by the auth uid.
    final profile = Profile(
      userId: uid,
      fullName: draft.fullName,
      roles: draft.roles,
      barangay: draft.barangay,
      phone: draft.phone,
      email: email,
      products: draft.products,
      barterWillingness: draft.barterWillingness,
      preferredTradeResources: draft.preferredTradeResources,
      farmLocation: farmLocation,
      farmSizeNote: draft.farmSizeNote,
      deviceType: draft.deviceType,
      dataPlan: draft.dataPlan,
      photoUrls: photoUrls,
      consentGiven: draft.consentGiven,
    );
    await repo.createProfile(profile);

    return ProfilingResult(uid: uid, email: email, starterPassword: password);
  }
}
