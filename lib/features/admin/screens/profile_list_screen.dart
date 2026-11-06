import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/profile.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/profiling_providers.dart';
import '../../../core/l10n/app_language.dart';

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

  static const _pickCooperative = -1;
  static const _noCooperative = '';

  /// Researcher-admin records which cooperative confirmed this farmer.
  /// Asked only for farmers who agreed to cooperative confirmation (C5);
  /// the cooperative is never told who declined.
  Future<void> _setCooperative(
      BuildContext context, WidgetRef ref, Profile p) async {
    final cooperatives = ref.read(cooperativesProvider).valueOrNull ?? const [];
    final picked = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Cooperative: ${p.fullName}'),
        children: [
          if (cooperatives.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Text('No cooperatives yet. Add one under '
                  'Researcher home → Cooperatives.'),
            ),
          for (final c in cooperatives)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(c.cooperativeId),
              child: Text(c.barangay == null ? c.name : '${c.name} (${c.barangay})'),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(_noCooperative),
            child: const Text('None / remove'),
          ),
        ],
      ),
    );
    if (picked == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(profileRepositoryProvider).setCooperative(
          p.userId, picked == _noCooperative ? null : picked);
    } catch (error) {
      messenger.showSnackBar(
          SnackBar(content: Text('Could not record the cooperative: $error')));
    }
  }

  /// Researcher-admin records the verification level (Table 3.4).
  Future<void> _setLevel(BuildContext context, WidgetRef ref, Profile p) async {
    final level = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Verification level: ${p.fullName}'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(Profile.levelVisited),
            child: const Text('Level 1: Visited by researchers'),
          ),
          SimpleDialogOption(
            onPressed: () =>
                Navigator.of(context).pop(Profile.levelCooperativeConfirmed),
            child: const Text('Level 2: Cooperative-confirmed '
                '(only with consent C5 and the cooperative\'s confirmation)'),
          ),
          const Divider(),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(_pickCooperative),
            child: const Text('Record the cooperative (only with consent C5)'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (level == _pickCooperative) return _setCooperative(context, ref, p);
    if (level == null || level == p.verificationLevel) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(profileRepositoryProvider).setVerificationLevel(p.userId, level);
    } catch (error) {
      messenger.showSnackBar(
          SnackBar(content: Text('Could not change the level: $error')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(allProfilesProvider);
    final cooperativeNames = ref.watch(cooperativeNamesProvider);

    return Scaffold(
      appBar: AppBar(
          title: Text(context.tr('Profiled Accounts', 'Mga na-profile'))),
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
                    '${p.barangay} • ${p.roles.join(", ")}\n'
                    '${p.isAdmin ? 'Researcher-admin' : (p.verificationLabelFor(context.language) ?? 'Verification level not recorded')}'
                    '${p.cooperativeId == null ? '' : '\nCooperative: ${cooperativeNames[p.cooperativeId] ?? 'unknown'}'}'
                    '${p.isClaimed ? '\nMoved to a phone sign-in' : ''}'
                    '${p.claimedFrom != null ? '\nSigns in by phone (claimed)' : ''}'
                    '${p.products.isEmpty ? '' : '\n${p.products.join(", ")}'}'),
                isThreeLine: true,
                onTap: p.isAdmin ? null : () => _setLevel(context, ref, p),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: p.consentGiven
                          ? 'Consent recorded'
                          : 'Consent not recorded',
                      child: p.consentGiven
                          ? const Icon(Icons.task_alt, color: Colors.green)
                          : const Icon(Icons.pending_outlined),
                    ),
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
