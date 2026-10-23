import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/profile.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/profiling_providers.dart';

/// Read-back half of the Sprint 1 vertical slice: every saved
/// profile streams live from Firestore into this list.
class ProfileListScreen extends ConsumerWidget {
  const ProfileListScreen({super.key});

  Future<void> _toggleHidden(
      BuildContext context, WidgetRef ref, Profile p) async {
    final hide = !p.hidden;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(hide ? 'Hide ${p.fullName}?' : 'Unhide ${p.fullName}?'),
        content: Text(hide
            ? 'Their listings leave the marketplace and search, and others '
                'see "This profile is unavailable." on offers and chats.'
            : 'Their profile and listings become visible again.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(hide ? 'HIDE' : 'UNHIDE')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final adminUid = ref.read(authStateProvider).valueOrNull?.uid;
    if (adminUid == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(profileRepositoryProvider)
          .setHidden(uid: p.userId, hidden: hide, byUid: adminUid);
    } catch (error) {
      messenger.showSnackBar(
          SnackBar(content: Text('Could not change visibility: $error')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(allProfilesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profiled Accounts')),
      body: profilesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load profiles:\n$e')),
        data: (profiles) {
          if (profiles.isEmpty) {
            return const Center(
                child: Text('No profiles yet. Start with "Profile a Farmer".'));
          }
          return ListView.separated(
            itemCount: profiles.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final p = profiles[i];
              return ListTile(
                leading: CircleAvatar(
                    child: Text(p.fullName.isEmpty
                        ? '?'
                        : p.fullName[0].toUpperCase())),
                title: Text(p.hidden ? '${p.fullName} (hidden)' : p.fullName),
                subtitle: Text(
                    '${p.barangay} • ${p.roles.join(", ")}'
                    '${p.products.isEmpty ? '' : '\n${p.products.join(", ")}'}'),
                isThreeLine: p.products.isNotEmpty,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    p.consentGiven
                        ? const Icon(Icons.verified, color: Colors.green)
                        : const Icon(Icons.pending_outlined),
                    if (!p.isAdmin)
                      IconButton(
                        tooltip: p.hidden ? 'Unhide profile' : 'Hide profile',
                        icon: Icon(p.hidden
                            ? Icons.visibility_off
                            : Icons.visibility_outlined),
                        onPressed: () => _toggleHidden(context, ref, p),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
