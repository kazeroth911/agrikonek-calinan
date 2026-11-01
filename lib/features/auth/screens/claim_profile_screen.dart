import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_language.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/auth_providers.dart';

/// Shown after a phone sign-in that has no profile yet (paper §3.5.4).
/// Finds the researcher-prepared profile with the same verified number
/// and, once the farmer confirms it is theirs, links it to this account.
class ClaimProfileScreen extends ConsumerStatefulWidget {
  const ClaimProfileScreen({super.key, required this.phone});

  /// The phone number Firebase verified, in +639XXXXXXXXX form.
  final String phone;

  @override
  ConsumerState<ClaimProfileScreen> createState() => _ClaimProfileScreenState();
}

class _ClaimProfileScreenState extends ConsumerState<ClaimProfileScreen> {
  List<DocumentSnapshot<Map<String, dynamic>>> _found = const [];
  bool _searching = true;
  bool _claiming = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final docs = await ref
          .read(profileRepositoryProvider)
          .findClaimableProfiles(e164Phone: widget.phone, uid: uid);
      if (mounted) setState(() => _found = docs);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _claim(DocumentSnapshot<Map<String, dynamic>> found) async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    setState(() {
      _claiming = true;
      _error = null;
    });
    try {
      await ref
          .read(profileRepositoryProvider)
          .claimProfile(prepared: found, uid: uid);
      // The profile stream now finds this account's profile, and the
      // app opens the marketplace by itself.
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget body;
    if (_searching) {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(context.tr('Looking for your profile...',
              'Ginapangita ang imong profile...')),
        ],
      );
    } else if (_found.isEmpty) {
      body = EmptyState(
        icon: _error == null ? Icons.person_search : Icons.cloud_off,
        isError: _error != null,
        text: _error != null
            ? '${context.tr('Could not look up your profile.', 'Wala mapangita ang imong profile.')}\n$_error'
            : context.tr(
                'We could not find a profile for ${widget.phone}.\n\n'
                    'Your researcher prepares profiles on-site. Please ask '
                    'them to check the number they recorded.',
                'Walay profile nga nakit-an para sa ${widget.phone}.\n\n'
                    'Ang researcher ang nag-andam sa mga profile. Palihug '
                    'pangutan-a sila kung sakto ba ang numero nga ilang gisulat.'),
        action: OutlinedButton.icon(
          onPressed: _search,
          icon: const Icon(Icons.refresh),
          label: Text(context.tr('Try again', 'Sulayi pag-usab')),
        ),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
              _found.length == 1
                  ? context.tr('Is this you?', 'Ikaw ba kini?')
                  : context.tr('Which one is you?', 'Hain ka niini?'),
              style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            context.tr(
                'Your researcher prepared this profile during the farm visit.',
                'Gi-andam sa imong researcher kini nga profile sa pagbisita sa uma.'),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          for (final doc in _found) _ProfileChoice(
            data: doc.data() ?? const {},
            phone: widget.phone,
            busy: _claiming,
            onPick: () => _claim(doc),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.visibility_off_outlined,
                  size: 20, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr(
                      'Your profile stays hidden from other users until you '
                          'choose to show it in My profile.',
                      'Magpabilin nga nakatago ang imong profile sa uban '
                          'hangtod nga imong ipakita kini sa Akong profile.'),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              '${context.tr('Could not link the profile', 'Wala ma-link ang profile')}: $_error',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const AgriKonekWordmark(fontSize: 22),
        actions: [
          TextButton(
            onPressed: _claiming
                ? null
                : () => ref.read(authServiceProvider).signOut(),
            child: Text(context.tr('Sign out', 'Mogawas')),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: body,
          ),
        ),
      ),
    );
  }
}

/// One prepared profile the farmer can pick as theirs.
class _ProfileChoice extends StatelessWidget {
  const _ProfileChoice({
    required this.data,
    required this.phone,
    required this.busy,
    required this.onPick,
  });

  final Map<String, dynamic> data;
  final String phone;
  final bool busy;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = (data['fullName'] ?? '') as String;
    final barangay = (data['barangay'] ?? '') as String;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    name.isEmpty ? '?' : name[0].toUpperCase(),
                    style: theme.textTheme.titleLarge
                        ?.copyWith(color: theme.colorScheme.onPrimary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: theme.textTheme.titleMedium),
                      Text('$barangay, Calinan',
                          style: theme.textTheme.bodyMedium),
                      Text(phone, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: busy ? null : onPick,
              child: busy
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : Text(context.tr('YES, THIS IS ME', 'OO, AKO KINI')),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when someone signs in to a prepared profile's original account
/// after it was claimed by a phone sign-in.
class MovedAccountScreen extends ConsumerWidget {
  const MovedAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: EmptyState(
        icon: Icons.phone_android,
        text: context.tr(
            'This profile now signs in with a phone number.\n'
                'Sign out, then choose "Use phone number instead".',
            'Kini nga profile mo-login na gamit ang numero sa cellphone.\n'
                'Mogawas, dayon pilia ang "Gamita ang numero sa cellphone".'),
        action: FilledButton(
          onPressed: () => ref.read(authServiceProvider).signOut(),
          child: Text(context.tr('Sign out', 'Mogawas')),
        ),
      ),
    );
  }
}
