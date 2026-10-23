import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/listing.dart';
import '../../../services/listing_repository.dart';
import '../providers/listing_providers.dart';
import '../widgets/listing_card.dart' show listingPriceLabel;
import 'listing_detail_screen.dart';
import 'post_listing_screen.dart';

/// The signed-in farmer's own listings, open and closed, so they can be
/// edited, re-opened or deleted even after they leave the marketplace.
class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  static String statusLabel(Listing l, DateTime now) {
    if (l.status == ListingStatus.closed) return 'Sold / closed';
    if (!ListingRepository.isOpenForFeed(l, now)) return 'Expired';
    return 'Active';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(myListingsProvider);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('My listings / Akong mga baligya')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const PostListingScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Post / Ibaligya'),
      ),
      body: listings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load your listings.\n$error',
                textAlign: TextAlign.center),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                    'You have not posted anything yet.\n'
                    'Wala pa kay gi-post nga baligya.',
                    textAlign: TextAlign.center),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final l = items[index];
              final status = statusLabel(l, now);
              return Card(
                child: ListTile(
                  leading: Icon(status == 'Active'
                      ? Icons.storefront
                      : Icons.inventory_2_outlined),
                  title: Text(l.title),
                  subtitle: Text('${listingPriceLabel(l)} · $status'),
                  trailing: IconButton(
                    tooltip: 'Edit',
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
