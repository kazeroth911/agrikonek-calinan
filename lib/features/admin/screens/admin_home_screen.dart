import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../../notifications/widgets/notification_bell.dart';
import 'profile_list_screen.dart';
import 'profiling_form_screen.dart';

/// Researcher-admin landing screen: jump to the profiling form
/// or review existing pre-profiled accounts.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AgriKonek — Researcher'),
        actions: [
          const NotificationBell(),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (profile != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text('Signed in as ${profile.fullName} (admin)',
                  style: Theme.of(context).textTheme.bodyLarge),
            ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_add_alt_1, size: 36),
              title: const Text('Profile a Farmer'),
              subtitle:
                  const Text('Field profiling form — creates account + profile'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const ProfilingFormScreen())),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.groups, size: 36),
              title: const Text('Profiled Accounts'),
              subtitle: const Text('Review and verify preloaded profiles'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const ProfileListScreen())),
            ),
          ),
        ],
      ),
    );
  }
}
