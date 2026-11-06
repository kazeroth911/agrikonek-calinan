import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/barter_proposal.dart';
import '../../../services/barter_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../notifications/widgets/notification_bell.dart';
import '../providers/barter_providers.dart';
import '../widgets/negotiation_widgets.dart';
import 'barter_detail_screen.dart';
import '../../../core/l10n/app_language.dart';

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
          title: Text(context.tr('Barters', 'Mga Baylo')),
          actions: const [NotificationBell()],
          bottom: TabBar(tabs: [
            Tab(text: context.tr('Incoming', 'Padulong')),
            Tab(text: context.tr('Sent', 'Gipadala')),
          ]),
        ),
        body: TabBarView(
          children: [
            _BarterList(
              provider: incomingBarterProvider,
              emptyText: context.tr('No barter proposals on your listings yet.',
                  'Wala pay nagtanyag og baylo sa imong mga baligya.'),
            ),
            _BarterList(
              provider: myBarterProposalsProvider,
              emptyText: context.tr('You have not proposed any barters yet.',
                  'Wala pa kay gitanyag nga baylo.'),
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
        text: '${context.tr('Could not load barters.', 'Wala ma-load ang mga baylo.')}\n\n$e',
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
                      ? context.tr('Listing', 'Baligya')
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
                        child: Text('${context.tr('For', 'Ilisan sa')}: $offered',
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
