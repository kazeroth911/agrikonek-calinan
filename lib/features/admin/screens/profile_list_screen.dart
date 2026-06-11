import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/profiling_providers.dart';

/// Read-back half of the Sprint 1 vertical slice: every saved
/// profile streams live from Firestore into this list.
class ProfileListScreen extends ConsumerWidget {
  const ProfileListScreen({super.key});

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
                title: Text(p.fullName),
                subtitle: Text(
                    '${p.barangay} • ${p.roles.join(", ")}'
                    '${p.products.isEmpty ? '' : '\n${p.products.join(", ")}'}'),
                isThreeLine: p.products.isNotEmpty,
                trailing: p.consentGiven
                    ? const Icon(Icons.verified, color: Colors.green)
                    : const Icon(Icons.pending_outlined),
              );
            },
          );
        },
      ),
    );
  }
}
