import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/offer.dart';
import '../../../services/offer_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/offer_providers.dart';
import '../widgets/negotiation_widgets.dart';

/// Live view of one bid negotiation: current amount, full append-only
/// history, and Accept / Reject / Counter — shown only to the party
/// whose turn it is (OfferRepository.canAct).
class OfferDetailScreen extends ConsumerStatefulWidget {
  const OfferDetailScreen({super.key, required this.offerId});

  final String offerId;

  @override
  ConsumerState<OfferDetailScreen> createState() => _OfferDetailScreenState();
}

class _OfferDetailScreenState extends ConsumerState<OfferDetailScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Action failed / Wala midagan: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _counterDialog(Offer offer, String uid) async {
    final controller = TextEditingController();
    final amount = await showDialog<num>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Counter offer / Counter nga tanyag'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'New amount (₱) / Bag-ong kantidad',
            prefixText: '₱ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              final parsed =
                  num.tryParse(controller.text.trim().replaceAll(',', ''));
              if (parsed != null && parsed > 0) {
                Navigator.of(context).pop(parsed);
              }
            },
            child: const Text('SEND COUNTER'),
          ),
        ],
      ),
    );
    if (amount != null) {
      await _run(() => ref
          .read(offerControllerProvider)
          .counter(offer: offer, byUserId: uid, amount: amount));
    }
  }

  @override
  Widget build(BuildContext context) {
    final offerAsync = ref.watch(offerDetailProvider(widget.offerId));
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Bid / Tanyag')),
      body: offerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => NegotiationListMessage(
          icon: Icons.cloud_off,
          text: 'Could not load this bid.\n$e',
        ),
        data: (offer) {
          if (offer == null || uid == null) {
            return const NegotiationListMessage(
              icon: Icons.search_off,
              text: 'This bid no longer exists. / Wala na kini nga bid.',
            );
          }
          return _body(context, offer, uid);
        },
      ),
    );
  }

  Widget _body(BuildContext context, Offer offer, String uid) {
    final theme = Theme.of(context);
    final isBuyer = uid == offer.buyerId;
    final canAct = OfferRepository.canAct(offer, uid);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(offer.listingTitle.isEmpty ? 'Listing' : offer.listingTitle,
            style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(isBuyer
            ? 'You are the buyer. / Ikaw ang mopalit.'
            : 'You are the seller. / Ikaw ang namaligya.'),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current offer / Kasamtangang tanyag',
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(pesos(offer.amount),
                    style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                StatusChip(statusName: offer.status.name),
                if (offer.message != null) ...[
                  const SizedBox(height: 12),
                  Text('"${offer.message}"',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('History / Kasaysayan', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (offer.history.isEmpty)
          const Text('No history yet.')
        else
          for (final entry in offer.history.reversed)
            _HistoryTile(entry: entry, offer: offer, viewerUid: uid),
        const SizedBox(height: 24),
        if (canAct) ...[
          FilledButton.icon(
            onPressed: _busy
                ? null
                : () => _run(() => ref
                    .read(offerControllerProvider)
                    .accept(offer: offer, byUserId: uid)),
            icon: const Icon(Icons.check),
            label: Text('Accept ${pesos(offer.amount)} / Dawata'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _busy ? null : () => _counterDialog(offer, uid),
            icon: const Icon(Icons.swap_vert),
            label: const Text('Counter / Mag-counter'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () => _run(() => ref
                    .read(offerControllerProvider)
                    .reject(offer: offer, byUserId: uid)),
            icon: const Icon(Icons.close),
            label: const Text('Reject / Balibari'),
          ),
        ] else if (offer.status == OfferStatus.pending ||
            offer.status == OfferStatus.countered)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Waiting for the other party to respond. / Naghulat sa '
                'tubag sa pikas.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.entry,
    required this.offer,
    required this.viewerUid,
  });

  final OfferHistoryEntry entry;
  final Offer offer;
  final String viewerUid;

  @override
  Widget build(BuildContext context) {
    final who = entry.byUserId == viewerUid
        ? 'You / Ikaw'
        : entry.byUserId == offer.buyerId
            ? 'Buyer / Pumapalit'
            : 'Seller / Namaligya';
    final showAmount = entry.action == 'bid' || entry.action == 'counter';

    return Card(
      child: ListTile(
        leading: Icon(switch (entry.action) {
          'accept' => Icons.check_circle,
          'reject' => Icons.cancel,
          'counter' => Icons.swap_vert,
          _ => Icons.gavel,
        }),
        title: Text('$who ${negotiationActionLabel(entry.action)}'
            '${showAmount ? ' — ${pesos(entry.amount)}' : ''}'),
        subtitle: entry.at == null
            ? null
            : Text(negotiationDateLabel.format(entry.at!)),
      ),
    );
  }
}
