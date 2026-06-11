import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/validators.dart';
import '../../../services/auth_service.dart';
import '../providers/auth_providers.dart';

/// Phone-OTP sign-in for farmers without email addresses (paper §4.6).
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
              _error = AuthService.friendlyError(e);
              _busy = false;
            });
          }
        }
      },
      onFailed: (e) => setState(() {
        _error = AuthService.friendlyError(e);
        _busy = false;
      }),
      onCodeSent: (verificationId, _) => setState(() {
        _verificationId = verificationId;
        _busy = false;
      }),
      onTimeout: (verificationId) {
        _verificationId ??= verificationId;
      },
    );
  }

  Future<void> _confirmCode() async {
    if (_codeController.text.trim().length < 6) {
      setState(() => _error = 'Enter the 6-digit code from the SMS.');
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
      setState(() => _error = AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in with OTP')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_codeStage) ...[
                  Text('Enter your mobile number. We will send a code by SMS.\n'
                      'Isulat ang imong numero. Padalhan ka namo og code.',
                      style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Mobile number',
                      hintText: '09XXXXXXXXX',
                      prefixIcon: Icon(Icons.phone_android),
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
                        : const Text('SEND CODE'),
                  ),
                ] else ...[
                  Text('Enter the 6-digit code sent to your phone.\n'
                      'Isulat ang 6-digit nga code gikan sa SMS.',
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
                    child: const Text('VERIFY & SIGN IN'),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _verificationId = null),
                    child: const Text('Change number / re-send code'),
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
