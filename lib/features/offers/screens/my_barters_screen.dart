import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/barter_proposal.dart';
import '../../../services/barter_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/barter_providers.dart';
import '../widgets/negotiation_widgets.dart';
import 'barter_detail_screen.dart';

/// Every barter the signed-in user is part of: Incoming (on their
/// listings) and Sent (proposals they made), each a live stream.
class MyBartersScreen extends ConsumerWidget {
  const MyBartersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Barters / Mga Baylo'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Incoming / Padulong'),
            Tab(text: 'Sent / Gipadala'),
          ]),
        ),
        body: TabBarView(
          children: [
            _BarterList(
              provider: incomingBarterProvider,
              emptyText: 'No barter proposals on your listings yet.\n'
                  'Wala pay nagtanyag og baylo sa imong mga baligya.',
            ),
            _BarterList(
              provider: myBarterProposalsProvider,
              emptyText: 'You have not proposed any barters yet.\n'
                  'Wala pa kay gitanyag nga baylo.',
            ),
          ],
        ),
      ),
    );
  }
}

class _BarterList extends ConsumerWidget {
  const _BarterList({required this.provider, required this.emptyText});

  final ProviderListenable<AsyncValue<List<BarterProposal>>> provider;
  final String emptyText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bartersAsync = ref.watch(provider);
    final uid = ref.watch(authStateProvider).valueOrNull?.uid ?? '';

    return bartersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => NegotiationListMessage(
        icon: Icons.cloud_off,
        text: 'Could not load barters.\nWala ma-load ang mga baylo.\n\n$e',
      ),
      data: (proposals) {
        if (proposals.isEmpty) {
          return NegotiationListMessage(
              icon: Icons.swap_horiz, text: emptyText);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: proposals.length,
          itemBuilder: (context, i) {
            final proposal = proposals[i];
            final offered =
                proposal.offeredItems.map((e) => e.toString()).join(', ');
            return Card(
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  proposal.listingTitle.isEmpty
                      ? 'Listing'
                      : proposal.listingTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (offered.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('For: $offered',
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          StatusChip(statusName: proposal.status.name),
                          if (BarterRepository.canAct(proposal, uid))
                            const YourMoveBadge(),
                        ],
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        BarterDetailScreen(barterId: proposal.barterId))),
              ),
            );
          },
        );
      },
    );
  }
}
