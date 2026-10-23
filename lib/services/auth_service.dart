import 'package:firebase_auth/firebase_auth.dart';
import 'push_notification_service.dart';

/// Thin wrapper over FirebaseAuth so screens never touch the SDK directly.
class AuthService {
  AuthService(this._auth);

  final FirebaseAuth _auth;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
  }

  /// Starts phone-OTP sign-in. Callbacks mirror the FirebaseAuth API so
  /// the screen layer can drive the UI (auto-retrieval vs manual entry).
  Future<void> startPhoneSignIn({
    required String e164Phone,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
    required void Function(FirebaseAuthException e) onFailed,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String verificationId) onTimeout,
  }) {
    return _auth.verifyPhoneNumber(
      phoneNumber: e164Phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: onAutoVerified,
      verificationFailed: onFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onTimeout,
    );
  }

  Future<UserCredential> confirmSmsCode({
    required String verificationId,
    required String smsCode,
  }) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithCredential(AuthCredential credential) =>
      _auth.signInWithCredential(credential);

  Future<void> signOut() async {
    await PushNotificationService.instance.unregisterCurrentDeviceToken();

    await _auth.signOut();
  }

  /// Maps FirebaseAuth error codes to farmer-friendly messages.
  static String friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return 'Email or password is incorrect. / Sayop ang email o password.';
        case 'invalid-email':
          return 'That email address is not valid.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and try again.';
        case 'network-request-failed':
          return 'No internet connection. / Walay koneksyon sa internet.';
        case 'invalid-verification-code':
          return 'The code you entered is incorrect. Please check the SMS.';
        default:
          return 'Sign-in failed (${error.code}). Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
