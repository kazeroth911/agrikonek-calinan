import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/profile.dart';
import '../../../services/admin_account_service.dart';
import '../../auth/providers/auth_providers.dart';

/// Stream of all profiles for the admin list (optionally filtered later).
///
/// Re-subscribes on every auth change. Without this, a sign-out cancels
/// the live snapshot listener with permission-denied, the provider caches
/// that AsyncError, and the next signed-in admin inherits it since nothing
/// else would tell Riverpod to rebuild this provider.
final allProfilesProvider = StreamProvider<List<Profile>>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(profileRepositoryProvider).watchAllProfiles();
});

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

/// Orchestrates the full profiling save (paper §3.5.4):
/// 1. create the login on the secondary app (admin stays signed in);
///    the credentials stay with the researchers during Phase 2
/// 2. write the profile HIDDEN, with its verification level (Table 3.4)
/// No farm photographs are taken (Table 3.14). If step 2 fails, the new
/// login is deleted again so the researcher can retry with the same email.
final profilingControllerProvider =
    Provider<ProfilingController>((ref) => ProfilingController(ref));

class ProfilingController {
  ProfilingController(this._ref);
  final Ref _ref;

  Future<ProfilingResult> saveNewFarmer({
    required Profile draft,
    required String email,
    String? starterPassword,
    GeoPoint? farmLocation,
    int verificationLevel = Profile.levelVisited,
  }) async {
    final adminUid = _ref.read(authStateProvider).valueOrNull?.uid;
    if (adminUid == null) throw StateError('Sign in as a researcher first.');

    final accounts = _ref.read(adminAccountServiceProvider);
    final repo = _ref.read(profileRepositoryProvider);

    final password =
        starterPassword ?? AdminAccountService.generateStarterPassword();

    // 1. Auth account (secondary app keeps the admin session alive).
    final account = await accounts.createFarmerAuthAccount(
      email: email,
      password: password,
    );
    final uid = account.uid;

    try {
      // 2. Hidden profile document keyed by the auth uid.
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
        consentGiven: draft.consentGiven,
        verificationLevel: verificationLevel,
        cooperativeId: draft.cooperativeId,
      );
      await repo.createPreparedProfile(profile, byUid: adminUid);
    } catch (_) {
      // No profile, so no login either: keeps the email reusable.
      try {
        await account.rollback();
      } catch (_) {
        // Rolling back is best-effort; the original error matters more.
      }
      rethrow;
    }
    await account.finish();

    return ProfilingResult(uid: uid, email: email, starterPassword: password);
  }
}
