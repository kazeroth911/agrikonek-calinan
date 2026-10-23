import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// A farmer login just created on the secondary app. Keep it until the
/// profile is saved: [rollback] deletes the login if the save fails, so a
/// dropped connection never leaves an account without a profile (whose
/// email could then not be reused).
class NewFarmerAccount {
  NewFarmerAccount._(this.uid, this._user, this._auth);

  final String uid;
  final User _user;
  final FirebaseAuth _auth;

  /// Deletes the login. Allowed because it was created seconds ago.
  Future<void> rollback() async {
    try {
      await _user.delete();
    } finally {
      await _auth.signOut();
    }
  }

  /// Ends the secondary session once the profile is safely saved.
  Future<void> finish() => _auth.signOut();
}

/// SOLO-DEV GOTCHA, SOLVED:
/// Calling createUserWithEmailAndPassword on the default FirebaseAuth
/// instance signs the *admin* out and signs the new farmer in — which
/// would break the field-profiling flow after every saved profile.
///
/// Fix: create farmer credentials on a SECONDARY Firebase app instance
/// whose auth session is independent of the admin's.
class AdminAccountService {
  static const _secondaryAppName = 'agrikonek-admin-secondary';

  Future<FirebaseApp> _secondaryApp() async {
    try {
      return Firebase.app(_secondaryAppName);
    } catch (_) {
      final defaultApp = Firebase.app();
      return Firebase.initializeApp(
        name: _secondaryAppName,
        options: defaultApp.options,
      );
    }
  }

  /// Creates a Firebase Auth account for a farmer. The admin's own
  /// session is untouched. Call [NewFarmerAccount.finish] after the
  /// profile saves, or [NewFarmerAccount.rollback] if it fails.
  Future<NewFarmerAccount> createFarmerAuthAccount({
    required String email,
    required String password,
  }) async {
    final app = await _secondaryApp();
    final secondaryAuth = FirebaseAuth.instanceFor(app: app);
    try {
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      return NewFarmerAccount._(user.uid, user, secondaryAuth);
    } on FirebaseAuthException {
      await secondaryAuth.signOut();
      rethrow;
    }
  }

  /// Characters for the printable starter password on the credential slip
  /// (paper §3.4). Ambiguous characters (0/O, 1/l/I) are left out.
  static const passwordAlphabet = 'abcdefghjkmnpqrstuvwxyz23456789';

  /// Random starter password from the operating system's secure random
  /// source, so it cannot be guessed from the time it was made.
  static String generateStarterPassword({int length = 8, Random? random}) {
    final rng = random ?? Random.secure();
    return List.generate(
      length,
      (_) => passwordAlphabet[rng.nextInt(passwordAlphabet.length)],
    ).join();
  }
}
