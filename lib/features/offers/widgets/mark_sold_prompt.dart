import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/listing.dart';
import '../../auth/providers/auth_providers.dart';
import '../../listings/providers/listing_providers.dart';

/// After a bid or barter is accepted, reminds the listing owner that the
/// listing is still open and offers to mark it sold. Not automatic: a
/// farmer selling several sacks may want to keep taking bids.
class MarkSoldPrompt extends ConsumerStatefulWidget {
  const MarkSoldPrompt({
    super.key,
    required this.listingId,
    required this.ownerId,
  });

  final String listingId;
  final String ownerId;

  @override
  ConsumerState<MarkSoldPrompt> createState() => _MarkSoldPromptState();
}

class _MarkSoldPromptState extends ConsumerState<MarkSoldPrompt> {
  bool _busy = false;

  Future<void> _markSold() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(listingRepositoryProvider).closeListing(widget.listingId);
      messenger.showSnackBar(const SnackBar(
          content: Text('Listing marked as sold. / Gimarkahan nga nabaligya.')));
    } catch (error) {
      messenger.showSnackBar(
          SnackBar(content: Text('Could not mark as sold: $error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;
    if (uid == null || uid != widget.ownerId) return const SizedBox.shrink();

    final listing =
        ref.watch(listingDetailProvider(widget.listingId)).valueOrNull;
    if (listing == null || listing.status != ListingStatus.active) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Deal accepted. "${listing.title}" is still open to others. / '
                'Nadawat na ang deal, pero bukas pa ang baligya.'),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _busy ? null : _markSold,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Mark listing as sold / Nabaligya na'),
            ),
          ],
        ),
      ),
    );
  }
}
