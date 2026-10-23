import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/profile.dart';
import '../../auth/providers/auth_providers.dart';

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
    if (hide) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Hide your profile?'),
          content: const Text(
              'Your listings will disappear from the marketplace and search. '
              'People you have offers or chats with will see '
              '"This profile is unavailable." and cannot send you new bids, '
              'barters or messages.\n\nYou can unhide it here at any time.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('CANCEL')),
            FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('HIDE')),
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
      messenger.showSnackBar(SnackBar(
          content: Text(hide
              ? 'Your profile is now hidden.'
              : 'Your profile is visible again.')));
    } catch (error) {
      messenger.showSnackBar(
          SnackBar(content: Text('Could not change visibility: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My profile / Akong profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load your profile.\n$error')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No profile found.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(profile.fullName, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(profile.barangay),
              if (profile.products.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(profile.products.join(', '),
                    style: theme.textTheme.bodySmall),
              ],
              const SizedBox(height: 24),
              Card(
                child: SwitchListTile(
                  value: profile.hidden,
                  onChanged:
                      _saving ? null : (on) => _setHidden(profile, on),
                  secondary: Icon(profile.hidden
                      ? Icons.visibility_off
                      : Icons.visibility_outlined),
                  title: const Text('Hide my profile / Itago'),
                  subtitle: Text(profile.hidden
                      ? 'Hidden: your listings are not shown to others.'
                      : 'Visible: others can see your listings and contact you.'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
