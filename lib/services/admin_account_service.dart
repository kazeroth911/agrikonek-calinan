import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// SOLO-DEV GOTCHA, SOLVED:
/// Calling createUserWithEmailAndPassword on the default FirebaseAuth
/// instance signs the *admin* out and signs the new farmer in — which
/// would break the field-profiling flow after every saved profile.
///
/// Fix: create farmer credentials on a SECONDARY Firebase app instance
/// whose auth session is independent of the admin's. The secondary
/// session is discarded immediately after the account is created.
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

  /// Creates a Firebase Auth account for a farmer and returns the new uid.
  /// The admin's own session is untouched.
  Future<String> createFarmerAuthAccount({
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
      final uid = credential.user!.uid;
      await secondaryAuth.signOut();
      return uid;
    } on FirebaseAuthException {
      await secondaryAuth.signOut();
      rethrow;
    }
  }

  /// Generates a simple printable starter password for the credential
  /// slip handed to the farmer during the field visit (paper §3.4).
  /// Avoids ambiguous characters (0/O, 1/l/I).
  static String generateStarterPassword({int length = 8}) {
    const chars = 'abcdefghjkmnpqrstuvwxyz23456789';
    final seed = DateTime.now().microsecondsSinceEpoch;
    final buffer = StringBuffer();
    var state = seed;
    for (var i = 0; i < length; i++) {
      state = (state * 1103515245 + 12345) & 0x7fffffff;
      buffer.write(chars[state % chars.length]);
    }
    return buffer.toString();
  }
}
