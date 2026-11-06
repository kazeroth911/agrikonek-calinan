import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/listing.dart';
import '../../../services/listing_repository.dart';
import '../providers/listing_providers.dart';
import '../widgets/listing_card.dart' show listingPriceLabel;
import 'listing_detail_screen.dart';
import 'post_listing_screen.dart';
import '../../../core/l10n/app_language.dart';

/// The signed-in farmer's own listings, open and closed, so they can be
/// edited, re-opened or deleted even after they leave the marketplace.
class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  static bool isActive(Listing l, DateTime now) =>
      l.status != ListingStatus.closed &&
      ListingRepository.isOpenForFeed(l, now);

  static String statusLabel(Listing l, DateTime now, AppLanguage language) {
    if (l.status == ListingStatus.closed) {
      return tr(language, 'Sold', 'Nabaligya');
    }
    if (!ListingRepository.isOpenForFeed(l, now)) {
      return tr(language, 'Expired', 'Lapas na');
    }
    return tr(language, 'Active', 'Aktibo');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(myListingsProvider);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('My listings', 'Akong mga baligya'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const PostListingScreen())),
        icon: const Icon(Icons.add),
        label: Text(context.tr('Post', 'Ibaligya')),
      ),
      body: listings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
                '${context.tr('Could not load your listings.', 'Wala ma-load ang imong mga baligya.')}\n$error',
                textAlign: TextAlign.center),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                    context.tr('You have not posted anything yet.',
                        'Wala pa kay gi-post nga baligya.'),
                    textAlign: TextAlign.center),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final l = items[index];
              final status = statusLabel(l, now, context.language);
              return Card(
                child: ListTile(
                  leading: Icon(isActive(l, now)
                      ? Icons.storefront
                      : Icons.inventory_2_outlined),
                  title: Text(l.title),
                  subtitle: Text(
                      '${listingPriceLabel(l, context.language)} · $status'),
                  trailing: IconButton(
                    tooltip: context.tr('Edit', 'Usba'),
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => PostListingScreen(existing: l))),
                  ),
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) =>
                              ListingDetailScreen(listingId: l.listingId))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
