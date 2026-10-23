import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/barter_proposal.dart';
import '../../../services/barter_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../chat/chat_launcher.dart';
import '../providers/barter_providers.dart';
import '../widgets/negotiation_widgets.dart';

/// Live view of one barter negotiation: offered vs requested items,
/// note, history with counter notes, and Accept / Reject / Counter for
/// whichever party's turn it is (BarterRepository.canAct).
class BarterDetailScreen extends ConsumerStatefulWidget {
  const BarterDetailScreen({super.key, required this.barterId});

  final String barterId;

  @override
  ConsumerState<BarterDetailScreen> createState() =>
      _BarterDetailScreenState();
}

class _BarterDetailScreenState extends ConsumerState<BarterDetailScreen> {
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

  Future<void> _counterDialog(BarterProposal proposal, String uid) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Counter the trade / I-counter ang baylo'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Describe your counter / Isulat ang imong counter',
            hintText: 'e.g. 2 sacks of compost instead of 1, pickup here',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.of(context).pop(text);
            },
            child: const Text('SEND COUNTER'),
          ),
        ],
      ),
    );
    if (note != null) {
      await _run(() => ref
          .read(barterControllerProvider)
          .counter(proposal: proposal, byUserId: uid, note: note));
    }
  }

  @override
  Widget build(BuildContext context) {
    final barterAsync = ref.watch(barterDetailProvider(widget.barterId));
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Barter / Baylo'),
        actions: [
          if (barterAsync.valueOrNull case final proposal? when uid != null)
            MessageIconButton(
              otherId: uid == proposal.proposerId
                  ? proposal.ownerId
                  : proposal.proposerId,
              listingId: proposal.listingId,
              listingTitle: proposal.listingTitle,
            ),
        ],
      ),
      body: barterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => NegotiationListMessage(
          icon: Icons.cloud_off,
          text: 'Could not load this barter.\n$e',
        ),
        data: (proposal) {
          if (proposal == null || uid == null) {
            return const NegotiationListMessage(
              icon: Icons.search_off,
              text: 'This proposal no longer exists. / Wala na kini.',
            );
          }
          return _body(context, proposal, uid);
        },
      ),
    );
  }

  Widget _body(BuildContext context, BarterProposal proposal, String uid) {
    final theme = Theme.of(context);
    final isProposer = uid == proposal.proposerId;
    final canAct = BarterRepository.canAct(proposal, uid);

    // Item directions are written from the proposer's point of view;
    // flip the headings for the listing owner.
    final givesHeading = isProposer
        ? 'You give / Imong ihatag'
        : 'They give / Ilang ihatag';
    final receivesHeading = isProposer
        ? 'You receive / Imong madawat'
        : 'They want / Ilang gusto';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
            proposal.listingTitle.isEmpty
                ? 'Listing'
                : proposal.listingTitle,
            style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(isProposer
            ? 'You proposed this trade. / Ikaw ang nagtanyag.'
            : 'Someone proposed a trade on your listing. / Adunay '
                'nagtanyag og baylo sa imong baligya.'),
        const SizedBox(height: 8),
        StatusChip(statusName: proposal.status.name),
        const SizedBox(height: 16),
        _ItemsCard(heading: givesHeading, items: proposal.offeredItems),
        const SizedBox(height: 12),
        _ItemsCard(heading: receivesHeading, items: proposal.requestedItems),
        if (proposal.note != null) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('"${proposal.note}"',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontStyle: FontStyle.italic)),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (proposal.history.isNotEmpty) ...[
          Text('History / Kasaysayan', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final entry in proposal.history.reversed)
            _HistoryTile(entry: entry, proposal: proposal, viewerUid: uid),
          const SizedBox(height: 16),
        ],
        if (canAct) ...[
          FilledButton.icon(
            onPressed: _busy
                ? null
                : () => _run(() => ref
                    .read(barterControllerProvider)
                    .accept(proposal: proposal, byUserId: uid)),
            icon: const Icon(Icons.check),
            label: const Text('Accept Trade / Dawata ang Baylo'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _busy ? null : () => _counterDialog(proposal, uid),
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Counter / Mag-counter'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () => _run(() => ref
                    .read(barterControllerProvider)
                    .reject(proposal: proposal, byUserId: uid)),
            icon: const Icon(Icons.close),
            label: const Text('Reject / Balibari'),
          ),
        ] else if (proposal.status == BarterStatus.pending ||
            proposal.status == BarterStatus.countered)
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

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.heading, required this.items});

  final String heading;
  final List<BarterItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(heading, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Text('—')
            else
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.eco, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item.toString())),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.entry,
    required this.proposal,
    required this.viewerUid,
  });

  final BarterHistoryEntry entry;
  final BarterProposal proposal;
  final String viewerUid;

  @override
  Widget build(BuildContext context) {
    final who = entry.byUserId == viewerUid
        ? 'You / Ikaw'
        : entry.byUserId == proposal.proposerId
            ? 'Proposer / Nagtanyag'
            : 'Owner / Tag-iya';

    return Card(
      child: ListTile(
        leading: Icon(switch (entry.action) {
          'accept' => Icons.check_circle,
          'reject' => Icons.cancel,
          'counter' => Icons.swap_horiz,
          _ => Icons.handshake,
        }),
        title: Text('$who ${negotiationActionLabel(entry.action)}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.note != null) Text('"${entry.note}"'),
            if (entry.at != null)
              Text(negotiationDateLabel.format(entry.at!)),
          ],
        ),
      ),
    );
  }
}
