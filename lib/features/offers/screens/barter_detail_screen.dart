import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/barter_proposal.dart';
import '../../../services/barter_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../chat/chat_launcher.dart';
import '../../profile/providers/visibility_providers.dart';
import '../../profile/widgets/profile_unavailable_banner.dart';
import '../providers/barter_providers.dart';
import '../widgets/mark_sold_prompt.dart';
import '../widgets/negotiation_widgets.dart';
import '../../../core/l10n/app_language.dart';

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
            SnackBar(
                content: Text(
                    '${context.tr('Action failed', 'Wala midagan')}: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirmWithdraw() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr(
            'Withdraw your proposal?', 'Bawion ang imong tanyag?')),
        content: Text(context.tr(
            'The other party will be told, and this negotiation will end.',
            'Mahibal-an sa pikas, ug matapos na kini nga tawaran.')),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.tr('CANCEL', 'KANSELAHON'))),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.tr('WITHDRAW', 'BAWION'))),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _counterDialog(BarterProposal proposal, String uid) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Counter the trade', 'I-counter ang baylo')),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: context.tr(
                'Describe your counter', 'Isulat ang imong counter'),
            hintText: context.tr(
                'e.g. 2 sacks of compost instead of 1, pickup here',
                'pananglitan: 2 ka sako nga abono imbes 1, kuhaon diri'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.tr('CANCEL', 'KANSELAHON')),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.of(context).pop(text);
            },
            child: Text(context.tr('SEND COUNTER', 'IPADALA')),
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
        title: Text(context.tr('Barter', 'Baylo')),
        actions: [
          if (barterAsync.valueOrNull case final proposal?
              when uid != null &&
                  !ref.watch(isProfileHiddenProvider(uid == proposal.proposerId
                      ? proposal.ownerId
                      : proposal.proposerId)))
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
          text:
              '${context.tr('Could not load this barter.', 'Wala ma-load kini nga baylo.')}\n$e',
        ),
        data: (proposal) {
          if (proposal == null || uid == null) {
            return NegotiationListMessage(
              icon: Icons.search_off,
              text: context.tr('This proposal no longer exists.',
                  'Wala na kini nga tanyag sa baylo.'),
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
    final otherHidden = ref.watch(isProfileHiddenProvider(
        isProposer ? proposal.ownerId : proposal.proposerId));
    final canAct = BarterRepository.canAct(proposal, uid) && !otherHidden;

    // Item directions are written from the proposer's point of view;
    // flip the headings for the listing owner.
    final givesHeading = isProposer
        ? context.tr('You give', 'Imong ihatag')
        : context.tr('They give', 'Ilang ihatag');
    final receivesHeading = isProposer
        ? context.tr('You receive', 'Imong madawat')
        : context.tr('They want', 'Ilang gusto');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (otherHidden) ...[
          ProfileUnavailableBanner(
              detail: context.tr('This barter can no longer be answered.',
                  'Dili na matubag kini nga baylo.')),
          const SizedBox(height: 16),
        ],
        Text(
            proposal.listingTitle.isEmpty
                ? context.tr('Listing', 'Baligya')
                : proposal.listingTitle,
            style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(isProposer
            ? context.tr('You proposed this trade.', 'Ikaw ang nagtanyag.')
            : context.tr('Someone proposed a trade on your listing.',
                'Adunay nagtanyag og baylo sa imong baligya.')),
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
          Text(context.tr('History', 'Kasaysayan'),
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final entry in proposal.history.reversed)
            _HistoryTile(entry: entry, proposal: proposal, viewerUid: uid),
          const SizedBox(height: 16),
        ],
        if (proposal.status == BarterStatus.accepted)
          MarkSoldPrompt(
              listingId: proposal.listingId, ownerId: proposal.ownerId),
        if (canAct) ...[
          FilledButton.icon(
            onPressed: _busy
                ? null
                : () => _run(() => ref
                    .read(barterControllerProvider)
                    .accept(proposal: proposal, byUserId: uid)),
            icon: const Icon(Icons.check),
            label: Text(context.tr('Accept Trade', 'Dawata ang Baylo')),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _busy ? null : () => _counterDialog(proposal, uid),
            icon: const Icon(Icons.swap_horiz),
            label: Text(context.tr('Counter', 'Mag-counter')),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () => _run(() => ref
                    .read(barterControllerProvider)
                    .reject(proposal: proposal, byUserId: uid)),
            icon: const Icon(Icons.close),
            label: Text(context.tr('Decline', 'Balibari')),
          ),
        ] else if (proposal.status == BarterStatus.pending ||
            proposal.status == BarterStatus.countered) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                context.tr('Waiting for the other party to respond.',
                    'Naghulat sa tubag sa pikas.'),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
          if (BarterRepository.canWithdraw(proposal, uid)) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      if (!await _confirmWithdraw()) return;
                      await _run(() => ref
                          .read(barterControllerProvider)
                          .withdraw(proposal: proposal, byUserId: uid));
                    },
              icon: const Icon(Icons.undo),
              label: Text(context.tr(
                  'Withdraw my proposal', 'Bawion ang akong tanyag')),
            ),
          ],
        ],
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
        ? context.tr('You', 'Ikaw')
        : entry.byUserId == proposal.proposerId
            ? context.tr('Proposer', 'Nagtanyag')
            : context.tr('Owner', 'Tag-iya');

    return Card(
      child: ListTile(
        leading: Icon(switch (entry.action) {
          'accept' => Icons.check_circle,
          'reject' => Icons.cancel,
          'counter' => Icons.swap_horiz,
          _ => Icons.handshake,
        }),
        title: Text('$who ${negotiationActionLabel(context.language, entry.action)}'),
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
