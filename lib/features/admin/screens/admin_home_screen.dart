import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../announcements/screens/announcements_screen.dart';
import '../../auth/providers/auth_providers.dart';
import '../../notifications/widgets/notification_bell.dart';
import '../../settings/settings_screen.dart';
import 'cooperatives_screen.dart';
import 'profile_list_screen.dart';
import 'profiling_form_screen.dart';
import '../../../core/l10n/app_language.dart';

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
            icon: const Icon(Icons.settings_outlined),
            tooltip: context.tr('Settings', 'Mga Setting'),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const SettingsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: context.tr('Sign out', 'Mogawas'),
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
              title: Text(
                  context.tr('Profile a Farmer', 'I-profile ang Mag-uuma')),
              subtitle:
                  const Text('Field profiling form — creates account + profile'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const ProfilingFormScreen())),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.groups, size: 36),
              title: Text(context.tr('Profiled Accounts', 'Mga na-profile')),
              subtitle: const Text('Review and verify preloaded profiles'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const ProfileListScreen())),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.groups_outlined, size: 36),
              title: Text(context.tr('Cooperatives', 'Mga Kooperatiba')),
              subtitle: const Text(
                  'Partner cooperatives that confirm members who agreed (C5)'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const CooperativesScreen())),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.campaign, size: 36),
              title: Text(context.tr('Announcements', 'Mga Pahibalo')),
              subtitle: const Text(
                  'Send a notice to all farmers, one barangay, or chosen people'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const AnnouncementsScreen())),
            ),
          ),
        ],
      ),
    );
  }
}
