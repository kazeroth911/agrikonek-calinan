import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/offer.dart';
import '../../../services/offer_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../notifications/widgets/notification_bell.dart';
import '../providers/offer_providers.dart';
import '../widgets/negotiation_widgets.dart';
import 'offer_detail_screen.dart';
import '../../../core/l10n/app_language.dart';

/// Every bid the signed-in user is part of: Incoming (on their
/// listings) and Sent (bids they placed), each a live stream.
class MyOffersScreen extends ConsumerWidget {
  const MyOffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('Bids', 'Mga Tanyag')),
          actions: const [NotificationBell()],
          bottom: TabBar(tabs: [
            Tab(text: context.tr('Incoming', 'Padulong')),
            Tab(text: context.tr('Sent', 'Gipadala')),
          ]),
        ),
        body: TabBarView(
          children: [
            _OfferList(
              provider: incomingOffersProvider,
              emptyText: context.tr('No bids on your listings yet.',
                  'Wala pay nag-bid sa imong mga baligya.'),
            ),
            _OfferList(
              provider: myOffersProvider,
              emptyText: context.tr('You have not placed any bids yet.',
                  'Wala pa kay gipadala nga bid.'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferList extends ConsumerWidget {
  const _OfferList({required this.provider, required this.emptyText});

  final ProviderListenable<AsyncValue<List<Offer>>> provider;
  final String emptyText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(provider);
    final uid = ref.watch(authStateProvider).valueOrNull?.uid ?? '';

    return offersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => NegotiationListMessage(
        icon: Icons.cloud_off,
        text: '${context.tr('Could not load bids.', 'Wala ma-load ang mga bid.')}\n\n$e',
      ),
      data: (offers) {
        if (offers.isEmpty) {
          return NegotiationListMessage(
              icon: Icons.gavel, text: emptyText);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: offers.length,
          itemBuilder: (context, i) {
            final offer = offers[i];
            return Card(
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  offer.listingTitle.isEmpty
                      ? context.tr('Listing', 'Baligya')
                      : offer.listingTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(pesos(offer.amount),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w700)),
                      StatusChip(statusName: offer.status.name),
                      if (OfferRepository.canAct(offer, uid))
                        const YourMoveBadge(),
                    ],
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        OfferDetailScreen(offerId: offer.offerId))),
              ),
            );
          },
        );
      },
    );
  }
}
