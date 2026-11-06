import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/listing.dart';
import '../../../models/offer.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/offer_providers.dart';
import '../widgets/negotiation_widgets.dart';
import '../../../core/l10n/app_language.dart';

/// Opens the Place Bid bottom sheet from the listing detail screen.
Future<void> showPlaceBidSheet(BuildContext context, Listing listing) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true, // keep the form above the keyboard
    builder: (_) => PlaceBidSheet(listing: listing),
  );
}

/// Bid entry: amount + optional message. If the buyer already has an
/// open offer on this listing, the sheet revises it (a buyer-side
/// counter in the history) instead of creating a duplicate document.
class PlaceBidSheet extends ConsumerStatefulWidget {
  const PlaceBidSheet({super.key, required this.listing});

  final Listing listing;

  @override
  ConsumerState<PlaceBidSheet> createState() => _PlaceBidSheetState();
}

class _PlaceBidSheetState extends ConsumerState<PlaceBidSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _messageController = TextEditingController();

  bool _loadingExisting = true;
  Offer? _existingOffer;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) {
      setState(() => _loadingExisting = false);
      return;
    }
    try {
      final existing = await ref.read(offerControllerProvider).findOpenOffer(
          listingId: widget.listing.listingId, buyerId: uid);
      if (mounted) {
        setState(() {
          _existingOffer = existing;
          _loadingExisting = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingExisting = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    final amount =
        num.parse(_amountController.text.trim().replaceAll(',', ''));

    // Paper §3.5.5: a confirmation step before an offer is sent.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Send this offer?', 'Ipadala ang tanyag?')),
        content: Text(context.tr(
            '${pesos(amount)} for "${widget.listing.title}".\n'
                'The seller will be notified.',
            '${pesos(amount)} para sa "${widget.listing.title}".\n'
                'Pahibal-on ang namaligya.')),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.tr('CANCEL', 'KANSELAHON'))),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.tr('SEND', 'IPADALA'))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final controller = ref.read(offerControllerProvider);
      final existing = _existingOffer;
      if (existing != null) {
        // Revise the open offer — recorded as a buyer-side counter so
        // the history stays complete and append-only.
        await controller.counter(
            offer: existing, byUserId: uid, amount: amount);
      } else {
        await controller.placeBid(
          listing: widget.listing,
          buyerId: uid,
          amount: amount,
          message: _messageController.text,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(existing == null
            ? context.tr('Bid sent!', 'Napadala na ang tanyag!')
            : context.tr('Bid updated!', 'Na-usab na ang tanyag!')),
      ));
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            '${tr(ref.read(languageProvider), 'Could not send bid', 'Wala napadala ang tanyag')}: $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final existing = _existingOffer;

    return Padding(
      // Lift the sheet above the soft keyboard.
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Text(context.tr('Place a Bid', 'Mag-bid'),
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(widget.listing.title, style: theme.textTheme.bodyLarge),
              if (widget.listing.price != null)
                Text(
                  '${context.tr('Asking price', 'Presyo nga gipangayo')}: ${pesos(widget.listing.price!)}'
                  '${widget.listing.unit == null ? '' : ' / ${widget.listing.unit}'}',
                  style: theme.textTheme.bodyMedium,
                ),
              const SizedBox(height: 16),
              if (_loadingExisting)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                ))
              else if (existing != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    context.tr(
                        'You already have an open bid of '
                            '${pesos(existing.amount)} '
                            '(${negotiationStatusLabel(context.language, existing.status.name)}).\n'
                            'Sending a new amount will update it.',
                        'Naa na kay bukas nga tanyag nga '
                            '${pesos(existing.amount)} '
                            '(${negotiationStatusLabel(context.language, existing.status.name)}).\n'
                            'Kung magpadala ka og bag-ong kantidad, ma-usab kini.'),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: context.tr('Your offer (₱) *', 'Imong tanyag (₱) *'),
                  prefixText: '₱ ',
                ),
                validator: (v) {
                  final raw = v?.trim().replaceAll(',', '') ?? '';
                  final parsed = num.tryParse(raw);
                  if (parsed == null || parsed <= 0) {
                    return context.tr('Enter a valid amount',
                        'Butangi og saktong kantidad');
                  }
                  return null;
                },
              ),
              if (existing == null) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _messageController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: context.tr('Message (optional)', 'Mensahe (opsyonal)'),
                    hintText: context.tr('e.g. Can I pick up on Saturday?',
                        'pananglitan: Pwede ko mokuha sa Sabado?'),
                  ),
                ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!,
                      style: TextStyle(color: theme.colorScheme.error)),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy || _loadingExisting ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5))
                    : Text(existing == null
                        ? context.tr('SEND BID', 'IPADALA')
                        : context.tr('UPDATE BID', 'USBA')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
