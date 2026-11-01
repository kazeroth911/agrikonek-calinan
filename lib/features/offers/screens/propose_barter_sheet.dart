import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/barter_proposal.dart';
import '../../../models/listing.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/barter_providers.dart';

/// Opens the Propose Barter bottom sheet from the listing detail screen.
Future<void> showProposeBarterSheet(BuildContext context, Listing listing) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true, // keep the form above the keyboard
    builder: (_) => ProposeBarterSheet(listing: listing),
  );
}

/// Mutable working copy of one barter item row.
class _ItemDraft {
  final name = TextEditingController();
  final quantity = TextEditingController();
  String? unit;

  void dispose() {
    name.dispose();
    quantity.dispose();
  }

  BarterItem? toItem() {
    final n = name.text.trim();
    if (n.isEmpty) return null;
    return BarterItem(
      name: n,
      quantity: num.tryParse(quantity.text.trim()),
      unit: unit,
    );
  }
}

/// Goods-for-goods proposal: what the proposer offers, what they ask
/// for in return (prefilled with the listing itself), and a note.
class ProposeBarterSheet extends ConsumerStatefulWidget {
  const ProposeBarterSheet({super.key, required this.listing});

  final Listing listing;

  @override
  ConsumerState<ProposeBarterSheet> createState() =>
      _ProposeBarterSheetState();
}

class _ProposeBarterSheetState extends ConsumerState<ProposeBarterSheet> {
  final List<_ItemDraft> _offered = [_ItemDraft()];
  final List<_ItemDraft> _requested = [_ItemDraft()];
  final _noteController = TextEditingController();
  bool _busy = false;
  String? _error;

  /// Common units; mirrors AppConstants.listingUnits but barter items
  /// may also be unit-less ("1 carabao"), so unit stays optional.
  static const _units = ['kg', 'sack', 'tray', 'dozen', 'piece', 'head'];

  @override
  void initState() {
    super.initState();
    // The natural ask is the listed product itself.
    _requested.first.name.text = widget.listing.title;
  }

  @override
  void dispose() {
    for (final d in [..._offered, ..._requested]) {
      d.dispose();
    }
    _noteController.dispose();
    super.dispose();
  }

  List<BarterItem> _items(List<_ItemDraft> drafts) =>
      drafts.map((d) => d.toItem()).whereType<BarterItem>().toList();

  Future<void> _submit() async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    final offered = _items(_offered);
    final requested = _items(_requested);
    if (offered.isEmpty) {
      setState(() => _error =
          'Add at least one item you are offering. / Butangi og bisan '
          'usa ka butang nga imong ibaylo.');
      return;
    }
    if (requested.isEmpty) {
      setState(() => _error =
          'Add at least one item you want in return. / Unsa may imong '
          'gusto nga kabaylo?');
      return;
    }

    // Paper §3.5.5: a confirmation step before an offer is sent.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send this proposal? / Ipadala ang tanyag?'),
        content: Text(
            'You give: ${offered.map((i) => i.toString()).join(', ')}\n'
            'You receive: ${requested.map((i) => i.toString()).join(', ')}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('SEND / IPADALA')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(barterControllerProvider).propose(
            listing: widget.listing,
            proposerId: uid,
            offeredItems: offered,
            requestedItems: requested,
            note: _noteController.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('Barter proposal sent! / Napadala na ang tanyag sa baylo!'),
      ));
    } catch (e) {
      setState(() => _error = 'Could not send proposal: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text('Propose a Barter / Tanyag og Baylo',
                style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('For: ${widget.listing.title}',
                style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            Text('You give / Imong ihatag',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._itemRows(_offered),
            const SizedBox(height: 16),
            Text('You receive / Imong madawat',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._itemRows(_requested),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note (optional) / Mensahe',
                hintText: 'e.g. Fresh harvest, can deliver to Poblacion',
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!,
                    style: TextStyle(color: theme.colorScheme.error)),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Text('SEND PROPOSAL / IPADALA'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _itemRows(List<_ItemDraft> drafts) {
    return [
      for (var i = 0; i < drafts.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: drafts[i].quantity,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Qty / Pila', isDense: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  initialValue: drafts[i].unit,
                  decoration:
                      const InputDecoration(labelText: 'Unit', isDense: true),
                  items: _units
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => drafts[i].unit = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: TextField(
                  controller: drafts[i].name,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                      labelText: 'Item / Butang *', isDense: true,
                      hintText: 'e.g. compost'),
                ),
              ),
              IconButton(
                tooltip: i == drafts.length - 1 ? 'Add item' : 'Remove item',
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          if (i == drafts.length - 1) {
                            drafts.add(_ItemDraft());
                          } else {
                            drafts.removeAt(i).dispose();
                          }
                        }),
                icon: Icon(
                    i == drafts.length - 1 ? Icons.add_circle : Icons.remove_circle),
              ),
            ],
          ),
        ),
    ];
  }
}
