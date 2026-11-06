import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/validators.dart';
import '../../../services/auth_service.dart';
import '../providers/auth_providers.dart';
import '../../../core/l10n/app_language.dart';

/// Phone sign-in for farmers (paper §3.5.4). After the SMS code is
/// confirmed, HomeShell offers the prepared profile with this number.
/// Two stages on one screen: enter phone -> enter the 6-digit SMS code.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _verificationId;
  bool _busy = false;
  String? _error;

  bool get _codeStage => _verificationId != null;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = ref.read(authServiceProvider);
    try {
      await auth.startPhoneSignIn(
        e164Phone: Validators.toE164Ph(_phoneController.text),
        onAutoVerified: (credential) async {
          // Some devices auto-read the SMS; sign in immediately.
          try {
            await auth.signInWithCredential(credential);
            if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
          } catch (e) {
            if (mounted) {
              setState(() {
                _error = AuthService.friendlyError(e, ref.read(languageProvider));
                _busy = false;
              });
            }
          }
        },
        // The SMS can arrive after the user has left this screen, so every
        // callback checks that the screen still exists first.
        onFailed: (e) {
          if (!mounted) return;
          setState(() {
            _error = AuthService.friendlyError(e, ref.read(languageProvider));
            _busy = false;
          });
        },
        onCodeSent: (verificationId, _) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _busy = false;
          });
        },
        onTimeout: (verificationId) {
          if (!mounted) return;
          _verificationId ??= verificationId;
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = AuthService.friendlyError(e, ref.read(languageProvider));
          _busy = false;
        });
      }
    }
  }

  Future<void> _confirmCode() async {
    if (_codeController.text.trim().length < 6) {
      setState(() => _error = context.tr('Enter the 6-digit code from the SMS.',
          'Isulat ang 6 ka numero nga code gikan sa SMS.'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).confirmSmsCode(
            verificationId: _verificationId!,
            smsCode: _codeController.text.trim(),
          );
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _error =
            AuthService.friendlyError(e, ref.read(languageProvider)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
          title: Text(context.tr('Sign in with phone', 'Mo-login gamit ang cellphone'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_codeStage) ...[
                  Text(
                      context.tr(
                          'Enter your mobile number. We will send a code by SMS.',
                          'Isulat ang imong numero. Padalhan ka namo og code.'),
                      style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: context.tr('Mobile number', 'Numero sa cellphone'),
                      hintText: '09XXXXXXXXX',
                      prefixIcon: const Icon(Icons.phone_android),
                    ),
                    validator: Validators.phPhone,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _sendCode,
                    child: _busy
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child:
                                CircularProgressIndicator(strokeWidth: 2.5))
                        : Text(context.tr('SEND CODE', 'IPADALA ANG CODE')),
                  ),
                ] else ...[
                  Text(
                      context.tr('Enter the 6-digit code sent to your phone.',
                          'Isulat ang 6-digit nga code gikan sa SMS.'),
                      style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(fontSize: 28, letterSpacing: 12),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(counterText: ''),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _confirmCode,
                    child: Text(context.tr('VERIFY & SIGN IN', 'I-VERIFY UG MO-LOGIN')),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _verificationId = null),
                    child: Text(context.tr('Change number / re-send code',
                        'Ilisi ang numero / ipadala pag-usab')),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!,
                      style: TextStyle(color: theme.colorScheme.error)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
