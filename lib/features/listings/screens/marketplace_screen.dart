import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/category_style.dart';
import '../../../core/widgets/empty_state.dart';
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
    final me = ref.watch(currentProfileProvider).valueOrNull;
    final meHidden = me?.hidden ?? false;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const PostListingScreen())),
        icon: const Icon(Icons.add),
        label: Text(context.tr('Post', 'Ibaligya')),
      ),
      body: Column(
        children: [
          _Header(
            name: me?.fullName ?? '',
            barangay: me?.barangay ?? '',
            onSignOut: () => ref.read(authServiceProvider).signOut(),
          ),
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
          const _CategoryChips(),
          Expanded(
            child: feed.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => _FeedMessage(
                icon: Icons.cloud_off,
                isError: true,
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: listings.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return _SectionTitle(count: listings.length);
                    }
                    final listing = listings[i - 1];
                    return ListingCard(
                      listing: listing,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ListingDetailScreen(
                              listingId: listing.listingId),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Green farmland header: greeting, quick actions and the search box.
class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.barangay,
    required this.onSignOut,
  });

  final String name;
  final String barangay;
  final VoidCallback onSignOut;

  String _greeting(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour < 12) return context.tr('Good morning', 'Maayong buntag');
    if (hour < 18) return context.tr('Good afternoon', 'Maayong hapon');
    return context.tr('Good evening', 'Maayong gabii');
  }

  @override
  Widget build(BuildContext context) {
    final firstName = name.trim().split(' ').first;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: HillsBackdrop(
        showSun: false,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AgriKonekMark(size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            firstName.isEmpty
                                ? _greeting(context)
                                : '${_greeting(context)}, $firstName!',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (barangay.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.place,
                                    size: 14, color: AppTheme.harvest),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '$barangay, Calinan',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.85),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const NotificationBell(color: Colors.white),
                    IconButton(
                      color: Colors.white,
                      icon: const Icon(Icons.account_circle_outlined),
                      tooltip: context.tr('My profile', 'Akong profile'),
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const MyProfileScreen())),
                    ),
                    IconButton(
                      color: Colors.white,
                      icon: const Icon(Icons.logout),
                      tooltip: context.tr('Sign out', 'Mogawas'),
                      onPressed: onSignOut,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('What are you looking for today?',
                      'Unsa imong gipangita karon?'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 14),
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: _SearchField(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.tr('Fresh from Calinan farms',
                  'Bag-o gikan sa mga uma sa Calinan'),
              style: theme.textTheme.titleMedium,
            ),
          ),
          Text(
            context.tr(
                '$count ${count == 1 ? 'listing' : 'listings'}',
                '$count ka baligya'),
            style: theme.textTheme.bodySmall,
          ),
        ],
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
        hintText: context.tr('Search durian, eggs, Wangan...',
            'Pangitaa: durian, itlog, Wangan...'),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _CategoryChips extends ConsumerWidget {
  const _CategoryChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoryProvider);
    final cebuano = context.language == AppLanguage.cebuano;

    return SizedBox(
      height: 64, // generous tap target for the chip row
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: const Icon(Icons.apps),
              label: Text(context.tr('All', 'Tanan')),
              selected: selected == null,
              showCheckmark: false,
              onSelected: (_) =>
                  ref.read(selectedCategoryProvider.notifier).state = null,
            ),
          ),
          for (final category in AppConstants.listingCategories)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(CategoryStyle.of(category).icon),
                label: Text(cebuano
                    ? CategoryStyle.cebuanoName(category)
                    : category),
                selected: selected == category,
                showCheckmark: false,
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
  const _FeedMessage(
      {required this.icon, required this.text, this.isError = false});
  final IconData icon;
  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) =>
      EmptyState(icon: icon, text: text, isError: isError);
}
