import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_providers.dart';
import '../../notifications/widgets/notification_bell.dart';
import '../../profile/screens/my_profile_screen.dart';
import '../providers/listing_providers.dart';
import '../widgets/listing_card.dart';
import 'listing_detail_screen.dart';
import 'post_listing_screen.dart';
import '../../../core/l10n/app_language.dart';

/// Sprint 2 centerpiece: the categorized marketplace feed.
/// Live Firestore stream + keyword search + category chips, designed
/// for one-handed use on 720x1280 low-end screens.
class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(filteredFeedProvider);
    final meHidden =
        ref.watch(currentProfileProvider).valueOrNull?.hidden ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Calinan Marketplace', 'Merkado sa Calinan')),
        actions: [
          const NotificationBell(),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: context.tr('My profile', 'Akong profile'),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const MyProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: context.tr('Sign out', 'Mogawas'),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const PostListingScreen())),
        icon: const Icon(Icons.add),
        label: Text(context.tr('Post', 'Ibaligya')),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (meHidden)
              MaterialBanner(
                leading: const Icon(Icons.visibility_off),
                content: Text(context.tr(
                    'Your profile is hidden. Others cannot see your listings.',
                    'Nakatago ang imong profile. Dili makita sa uban ang imong mga baligya.')),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const MyProfileScreen())),
                    child: Text(context.tr('CHANGE', 'USBA')),
                  ),
                ],
              ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: _SearchField(),
            ),
            const _CategoryChips(),
            Expanded(
              child: feed.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => _FeedMessage(
                  icon: Icons.cloud_off,
                  text: '${context.tr('Could not load the marketplace. Please check your connection and try again.', 'Wala ma-load ang merkado. Palihug susiha ang imong koneksyon ug sulayi pag-usab.')}\n\n$e',
                ),
                data: (listings) {
                  if (listings.isEmpty) {
                    return _FeedMessage(
                      icon: Icons.storefront_outlined,
                      text: context.tr(
                          'No listings found.\n\n'
                              'Try another category or search word, or be the '
                              'first to post!',
                          'Walay nakit-an nga baligya.\n\n'
                              'Sulayi ang laing kategorya o pulong, o ikaw '
                              'ang unang mag-post!'),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                    itemCount: listings.length,
                    itemBuilder: (context, i) => ListingCard(
                      listing: listings[i],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ListingDetailScreen(
                              listingId: listings[i].listingId),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends ConsumerWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextField(
      onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: context.tr('Search (e.g. durian, eggs, Wangan)',
            'Pangitaa (pananglitan: durian, itlog, Wangan)'),
        isDense: true,
      ),
    );
  }
}

class _CategoryChips extends ConsumerWidget {
  const _CategoryChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoryProvider);

    return SizedBox(
      height: 56, // generous tap target for the chip row
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(context.tr('All', 'Tanan')),
              selected: selected == null,
              onSelected: (_) =>
                  ref.read(selectedCategoryProvider.notifier).state = null,
            ),
          ),
          for (final category in AppConstants.listingCategories)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(category),
                selected: selected == category,
                onSelected: (_) => ref
                    .read(selectedCategoryProvider.notifier)
                    .state = category,
              ),
            ),
        ],
      ),
    );
  }
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
