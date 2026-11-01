import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/barter_proposal.dart';
import '../../../models/listing.dart';
import '../../../models/offer.dart';
import '../../../services/listing_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../chat/chat_launcher.dart';
import '../../offers/providers/barter_providers.dart';
import '../../offers/providers/offer_providers.dart';
import '../../offers/screens/barter_detail_screen.dart';
import '../../offers/screens/offer_detail_screen.dart';
import '../../offers/screens/place_bid_sheet.dart';
import '../../offers/screens/propose_barter_sheet.dart';
import '../../offers/widgets/negotiation_widgets.dart';
import '../../profile/providers/visibility_providers.dart';
import '../../profile/widgets/profile_unavailable_banner.dart';
import '../../profile/widgets/verification_badge.dart';
import '../providers/listing_providers.dart';
import '../widgets/listing_card.dart' show listingPriceLabel;
import '../widgets/listing_map_preview.dart';
import 'post_listing_screen.dart';

/// Full listing view: photo gallery, price, farmer info with barangay,
/// straight-line distance preview (display only, per panel decision),
/// and the Message / Bid / Barter entry points. Owners see manage
/// actions (close/delete) instead.
class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingAsync = ref.watch(listingDetailProvider(listingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Listing / Baligya')),
      body: listingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load this listing.\n$e',
                textAlign: TextAlign.center),
          ),
        ),
        data: (listing) {
          if (listing == null) {
            return const Center(
                child: Text('This listing has been removed. / '
                    'Wala na kini nga baligya.'));
          }
          return _ListingDetailBody(listing: listing);
        },
      ),
    );
  }
}

class _ListingDetailBody extends ConsumerWidget {
  const _ListingDetailBody({required this.listing});

  final Listing listing;

  static final _dateLabel = DateFormat('MMM d, yyyy');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final viewerUid = ref.watch(authStateProvider).valueOrNull?.uid;
    final isOwner = viewerUid == listing.ownerId;
    final forSale = listing.modes.contains(ListingMode.sale);
    final forBarter = listing.modes.contains(ListingMode.barter);

    if (!isOwner && ref.watch(isProfileHiddenProvider(listing.ownerId))) {
      return const Column(
        children: [
          ProfileUnavailableBanner(
              detail: 'This listing is no longer shown in the marketplace.'),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _PhotoGallery(urls: listing.photoUrls),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (listing.status == ListingStatus.closed)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                      'This listing is closed. / Sirado na kini nga baligya.'),
                ),
              Text(listing.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                listingPriceLabel(listing),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text(listing.category)),
                  if (forBarter)
                    const Chip(label: Text('Open to barter / Baylo')),
                ],
              ),
              if (listing.availableFrom != null ||
                  listing.availableTo != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.event, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_availabilityLabel(),
                          style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ],
              if (listing.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Details', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(listing.description),
              ],
              const SizedBox(height: 16),
              _FarmerCard(listing: listing),
              if (ref.watch(ownerProfileProvider(listing.ownerId)).valueOrNull
                  case final owner? when owner.farmLocation != null) ...[
                const SizedBox(height: 12),
                ListingMapPreview(farm: owner.farmLocation!),
              ],
              const SizedBox(height: 24),
              if (isOwner)
                _OwnerActions(listing: listing)
              else if (ListingRepository.isOpenForFeed(
                  listing, DateTime.now()))
                _BuyerActions(
                    listing: listing, forSale: forSale, forBarter: forBarter),
            ],
          ),
        ),
      ],
    );
  }

  String _availabilityLabel() {
    final from = listing.availableFrom;
    final to = listing.availableTo;
    if (from != null && to != null) {
      return 'Available ${_dateLabel.format(from)} – ${_dateLabel.format(to)}';
    }
    if (from != null) return 'Available from ${_dateLabel.format(from)}';
    return 'Available until ${_dateLabel.format(to!)}';
  }
}

/// Swipeable gallery; falls back to a placeholder banner when the
/// listing has no photos (e.g. posted while Storage was unavailable).
class _PhotoGallery extends StatelessWidget {
  const _PhotoGallery({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      height: 220,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.agriculture, size: 72)),
    );
    if (urls.isEmpty) return placeholder;

    return SizedBox(
      height: 220,
      child: PageView.builder(
        itemCount: urls.length,
        itemBuilder: (context, i) => Image.network(
          urls[i],
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const Center(child: CircularProgressIndicator()),
          errorBuilder: (context, error, stack) => placeholder,
        ),
      ),
    );
  }
}

/// Farmer name, barangay, and the distance preview. Distance is a
/// straight-line estimate from device GPS to the consented farm
/// location — display only (proximity matching removed by the panel) —
/// and the line hides itself whenever location data is unavailable.
class _FarmerCard extends ConsumerWidget {
  const _FarmerCard({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final distanceAsync =
        ref.watch(listingDistanceKmProvider(listing.ownerId));
    final level = ref
            .watch(ownerProfileProvider(listing.ownerId))
            .valueOrNull
            ?.verificationLevel ??
        0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              child: Text(
                listing.ownerName.isEmpty
                    ? '?'
                    : listing.ownerName[0].toUpperCase(),
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(listing.ownerName, style: theme.textTheme.titleMedium),
                  if (level > 0) ...[
                    const SizedBox(height: 4),
                    VerificationBadge(level: level),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    children: [
                      const Icon(Icons.place, size: 16),
                      const SizedBox(width: 4),
                      Flexible(child: Text(listing.ownerBarangay)),
                    ],
                  ),
                  distanceAsync.when(
                    loading: () => Text('Checking distance...',
                        style: theme.textTheme.bodySmall),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (km) => km == null
                        ? const SizedBox.shrink()
                        : Text(
                            '≈ ${km.toStringAsFixed(1)} km from you '
                            '(straight-line)',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Message, bid and barter entry points for anyone who is not the owner.
class _BuyerActions extends ConsumerWidget {
  const _BuyerActions({
    required this.listing,
    required this.forSale,
    required this.forBarter,
  });

  final Listing listing;
  final bool forSale;
  final bool forBarter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () => openChatWith(
            context,
            ref,
            otherId: listing.ownerId,
            otherName: listing.ownerName,
            listingId: listing.listingId,
            listingTitle: listing.title,
          ),
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Message / Mensahe'),
        ),
        if (forSale) ...[
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () => showPlaceBidSheet(context, listing),
            icon: const Icon(Icons.gavel),
            label: const Text('Place a Bid / Mag-bid'),
          ),
        ],
        if (forBarter) ...[
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () => showProposeBarterSheet(context, listing),
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Propose Barter / Baylo'),
          ),
        ],
      ],
    );
  }
}

class _OwnerActions extends ConsumerWidget {
  const _OwnerActions({required this.listing});

  final Listing listing;

  /// Runs an owner action and shows a message if it fails, instead of
  /// failing silently.
  static Future<void> _attempt(
    BuildContext context,
    Future<void> Function() action, {
    required String failure,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$failure: $error')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(listingRepositoryProvider);
    final isActive = listing.status == ListingStatus.active;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('This is your listing. / Imoha kini nga baligya.',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        _ListingNegotiations(listing: listing),
        FilledButton.tonalIcon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => PostListingScreen(existing: listing))),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit Listing / Usba'),
        ),
        const SizedBox(height: 12),
        if (isActive)
          FilledButton.tonalIcon(
            onPressed: () => _attempt(
              context,
              () => repo.closeListing(listing.listingId),
              failure: 'Could not mark as sold',
            ),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Mark as Sold / Close'),
          )
        else
          FilledButton.tonalIcon(
            onPressed: () => _attempt(
              context,
              () => repo.updateListing(
                  listing.listingId, {'status': ListingStatus.active.name}),
              failure: 'Could not re-open',
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Re-open Listing / Ablihi pag-usab'),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete listing? / Papason ang baligya?'),
                content: const Text(
                    'This removes the listing permanently. / Mawala kini '
                    'nga baligya hangtod sa hangtod.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('CANCEL'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('DELETE / PAPASA'),
                  ),
                ],
              ),
            );
            if (confirmed != true || !context.mounted) return;
            final navigator = Navigator.of(context);
            final messenger = ScaffoldMessenger.of(context);
            try {
              await repo.deleteListing(listing.listingId);
              navigator.pop();
            } catch (error) {
              messenger.showSnackBar(
                  SnackBar(content: Text('Could not delete: $error')));
            }
          },
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete Listing / Papasa'),
        ),
      ],
    );
  }
}

/// Owner's live view of negotiations on this listing (Sprint 3) —
/// compact tiles that tap through to the full detail screens.
class _ListingNegotiations extends ConsumerWidget {
  const _ListingNegotiations({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final offers = ref
        .watch(listingOffersProvider(
            (listingId: listing.listingId, sellerId: listing.ownerId)))
        .valueOrNull;
    final barters = ref
        .watch(listingBartersProvider(
            (listingId: listing.listingId, ownerId: listing.ownerId)))
        .valueOrNull;

    final hasAny =
        (offers?.isNotEmpty ?? false) || (barters?.isNotEmpty ?? false);
    if (!hasAny) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          'No bids or barter proposals yet. / Wala pay tanyag.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Negotiations on this listing / Mga tanyag',
            style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final offer in offers ?? const <Offer>[])
          Card(
            child: ListTile(
              leading: const Icon(Icons.gavel),
              title: Text('Bid: ${pesos(offer.amount)}'),
              subtitle: StatusChip(statusName: offer.status.name),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      OfferDetailScreen(offerId: offer.offerId))),
            ),
          ),
        for (final proposal in barters ?? const <BarterProposal>[])
          Card(
            child: ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text(
                'Barter: ${proposal.offeredItems.map((i) => i.toString()).join(', ')}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: StatusChip(statusName: proposal.status.name),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      BarterDetailScreen(barterId: proposal.barterId))),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}
