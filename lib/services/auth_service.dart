import 'package:firebase_auth/firebase_auth.dart';
import 'push_notification_service.dart';
import '../core/l10n/app_language.dart';

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

  /// Maps FirebaseAuth error codes to farmer-friendly messages in the
  /// chosen language.
  static String friendlyError(Object error,
      [AppLanguage language = AppLanguage.english]) {
    String t(String en, String ceb) => tr(language, en, ceb);
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return t('Email or password is incorrect.',
              'Sayop ang email o password.');
        case 'invalid-email':
          return t('That email address is not valid.',
              'Dili husto ang email address.');
        case 'too-many-requests':
          return t('Too many attempts. Please wait a moment and try again.',
              'Daghan na kaayo nga pagsulay. Paghulat kadiyot ug sulayi pag-usab.');
        case 'network-request-failed':
          return t('No internet connection.', 'Walay koneksyon sa internet.');
        case 'invalid-verification-code':
          return t('The code you entered is incorrect. Please check the SMS.',
              'Sayop ang code. Tan-awa pag-usab ang SMS.');
        case 'email-already-in-use':
          return t(
              'That email already has an account. Use a different email '
                  'for this farmer.',
              'Naa nay account kini nga email. Gamit og laing email para '
                  'niini nga mag-uuma.');
        case 'weak-password':
          return t('That password is too weak. Use at least 6 characters.',
              'Huyang kaayo ang password. Gamit og labing menos 6 ka karakter.');
        default:
          return t('Sign-in failed (${error.code}). Please try again.',
              'Wala nakasulod (${error.code}). Sulayi pag-usab.');
      }
    }
    return t('Something went wrong. Please try again.',
        'Naay problema. Sulayi pag-usab.');
  }
}
