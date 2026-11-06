import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/profile.dart';
import '../../auth/providers/auth_providers.dart';
import '../../learn/learn_screen.dart';
import '../../listings/screens/my_listings_screen.dart';
import '../../settings/settings_screen.dart';
import '../widgets/verification_badge.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/l10n/app_language.dart';

/// The signed-in farmer's own profile, with the option to hide it from
/// the marketplace (a participant right in the study's consent terms).
class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  bool _saving = false;

  Future<void> _setHidden(Profile profile, bool hide) async {
    // Worded before any await, while the screen's context is safe to use.
    final done = hide
        ? context.tr('Your profile is now hidden.',
            'Nakatago na ang imong profile.')
        : context.tr('Your profile is visible again.',
            'Makita na usab ang imong profile.');
    final failed = context.tr(
        'Could not change visibility', 'Wala nausab ang pagpakita');
    if (hide) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.tr(
              'Hide your profile?', 'Itago ang imong profile?')),
          content: Text(context.tr(
              'Your listings will disappear from the marketplace and search. '
                  'People you have offers or chats with will see '
                  '"This profile is unavailable." and cannot send you new bids, '
                  'barters or messages.\n\nYou can unhide it here at any time.',
              'Mawala ang imong mga baligya sa merkado ug sa pagpangita. '
                  'Ang mga tawo nga imong ka-tanyag o ka-chat makakita og '
                  '"Dili na makita kini nga profile." ug dili na sila '
                  'makapadala og bag-ong tanyag, baylo o mensahe.\n\n'
                  'Mahimo nimo kining ipakita pag-usab dinhi bisan kanus-a.')),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(context.tr('CANCEL', 'KANSELAHON'))),
            FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(context.tr('HIDE', 'ITAGO'))),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(profileRepositoryProvider).setHidden(
            uid: profile.userId,
            hidden: hide,
            byUid: profile.userId,
          );
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$failed: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('My profile', 'Akong profile'))),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(
                child: Text('${context.tr('Could not load your profile.', 'Wala ma-load ang imong profile.')}\n$error')),
        data: (profile) {
          if (profile == null) {
            return Center(
                child: Text(context.tr(
                    'No profile found.', 'Walay profile nga nakit-an.')));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: HillsBackdrop(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white,
                          foregroundColor: theme.colorScheme.primary,
                          child: Text(
                            profile.fullName.isEmpty
                                ? '?'
                                : profile.fullName[0].toUpperCase(),
                            style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.primary),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.fullName,
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(color: Colors.white),
                              ),
                              Text(
                                '${profile.barangay}, Calinan',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.85)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (profile.verificationLevel > 0) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: VerificationBadge(level: profile.verificationLevel),
                ),
              ],
              if (profile.products.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final product in profile.products)
                      Chip(
                        avatar: const Icon(Icons.eco_outlined),
                        label: Text(product),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: Text(context.tr('My listings', 'Akong mga baligya')),
                  subtitle: Text(context.tr(
                      'Edit, re-open or delete what you posted',
                      'Usba, ablihi o papasa ang imong gi-post')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => const MyListingsScreen())),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.school_outlined),
                  title: Text(context.tr('Learn', 'Kat-onan')),
                  subtitle: Text(context.tr(
                      'Lessons on using the app and selling safely (coming soon)',
                      'Mga leksyon sa paggamit sa app ug luwas nga pagbaligya (umaabot pa)')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => const LearnScreen())),
                ),
              ),
              Card(
                child: SwitchListTile(
                  value: profile.hidden,
                  onChanged:
                      _saving ? null : (on) => _setHidden(profile, on),
                  secondary: Icon(profile.hidden
                      ? Icons.visibility_off
                      : Icons.visibility_outlined),
                  title: Text(context.tr('Hide my profile', 'Itago ang akong profile')),
                  subtitle: Text(profile.hidden
                      ? context.tr(
                          'Hidden: your listings are not shown to others.',
                          'Nakatago: dili makita sa uban ang imong mga baligya.')
                      : context.tr(
                          'Visible: others can see your listings and contact you.',
                          'Makita: makita sa uban ang imong mga baligya ug makontak ka nila.')),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.translate),
                  title: Text(context.tr('Language', 'Pinulongan')),
                  subtitle: Text(context.language.displayName),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => const SettingsScreen())),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
