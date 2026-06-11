import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin/screens/admin_home_screen.dart';
import '../auth/providers/auth_providers.dart';
import '../listings/screens/marketplace_screen.dart';
import '../offers/providers/barter_providers.dart';
import '../offers/providers/offer_providers.dart';
import '../offers/screens/my_barters_screen.dart';
import '../offers/screens/my_offers_screen.dart';

/// Routes the signed-in user by role:
///   admin  -> AdminHomeScreen (researcher profiling tools)
///   others -> bottom-nav shell: Market / Bids / Barters (Sprint 3)
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
        return const _FarmerShell();
      },
    );
  }
}

/// Bottom navigation for farmers/buyers/traders. IndexedStack keeps
/// each tab's scroll position and stream subscriptions alive, and the
/// badges show how many negotiations are waiting on the user's move.
class _FarmerShell extends ConsumerStatefulWidget {
  const _FarmerShell();

  @override
  ConsumerState<_FarmerShell> createState() => _FarmerShellState();
}

class _FarmerShellState extends ConsumerState<_FarmerShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final offerCount = ref.watch(offersNeedingActionProvider);
    final barterCount = ref.watch(bartersNeedingActionProvider);

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          MarketplaceScreen(),
          MyOffersScreen(),
          MyBartersScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Market',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: offerCount > 0,
              label: Text('$offerCount'),
              child: const Icon(Icons.gavel_outlined),
            ),
            selectedIcon: const Icon(Icons.gavel),
            label: 'Bids',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: barterCount > 0,
              label: Text('$barterCount'),
              child: const Icon(Icons.swap_horiz_outlined),
            ),
            selectedIcon: const Icon(Icons.swap_horiz),
            label: 'Barter',
          ),
        ],
      ),
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
