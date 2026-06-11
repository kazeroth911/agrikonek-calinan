import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin/screens/admin_home_screen.dart';
import '../auth/providers/auth_providers.dart';
import '../listings/screens/marketplace_screen.dart';

/// Routes the signed-in user by role:
///   admin  -> AdminHomeScreen (researcher profiling tools)
///   others -> MarketplaceScreen (Sprint 2 feed)
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return profileAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => _MissingProfileScreen(detail: e.toString()),
      data: (profile) {
        if (profile == null) return const _MissingProfileScreen();
        if (profile.isAdmin) return const AdminHomeScreen();
        return const MarketplaceScreen();
      },
    );
  }
}

/// Signed in but no profile document — e.g. an auth account exists
/// but the researcher has not yet completed/linked the profile.
class _MissingProfileScreen extends ConsumerWidget {
  const _MissingProfileScreen({this.detail});
  final String? detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_search, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Your account exists, but your profile is not yet set up.\n'
                'Please contact your researcher.',
                textAlign: TextAlign.center,
              ),
              if (detail != null) ...[
                const SizedBox(height: 8),
                Text(detail!, style: const TextStyle(fontSize: 12)),
              ],
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () =>
                    ref.read(authServiceProvider).signOut(),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
