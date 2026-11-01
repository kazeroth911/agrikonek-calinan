import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/app_language.dart';
import '../../../core/widgets/empty_state.dart';

final _pesoFormat = NumberFormat('#,##0.##');

String pesos(num amount) => '₱${_pesoFormat.format(amount)}';

/// Labels for the shared status names (OfferStatus and BarterStatus use
/// the same names), in the chosen language.
String negotiationStatusLabel(AppLanguage language, String statusName) {
  String t(String en, String ceb) => tr(language, en, ceb);
  switch (statusName) {
    case 'pending':
      return t('Pending', 'Naghulat');
    case 'accepted':
      return t('Accepted', 'Gidawat');
    case 'rejected':
      return t('Rejected', 'Wala gidawat');
    case 'countered':
      return t('Countered', 'Gi-counter');
    case 'withdrawn':
      return t('Withdrawn', 'Gibawi');
    default:
      return statusName;
  }
}

/// Labels for history actions, in the chosen language.
String negotiationActionLabel(AppLanguage language, String action) {
  String t(String en, String ceb) => tr(language, en, ceb);
  switch (action) {
    case 'bid':
      return t('placed a bid', 'nag-bid');
    case 'propose':
      return t('proposed a trade', 'nagtanyag og baylo');
    case 'counter':
      return t('countered', 'ni-counter');
    case 'accept':
      return t('accepted', 'midawat');
    case 'reject':
      return t('rejected', 'wala midawat');
    case 'withdraw':
      return t('withdrew the offer', 'gibawi ang tanyag');
    default:
      return action;
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.statusName});

  final String statusName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (statusName) {
      'accepted' => (scheme.primaryContainer, scheme.onPrimaryContainer),
      'rejected' => (scheme.errorContainer, scheme.onErrorContainer),
      'countered' => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      'withdrawn' => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
      _ => (scheme.secondaryContainer, scheme.onSecondaryContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        negotiationStatusLabel(context.language, statusName),
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// "Your move" marker shown on list tiles when the negotiation is
/// waiting on the signed-in user.
class YourMoveBadge extends StatelessWidget {
  const YourMoveBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        context.tr('Your move', 'Ikaw na'),
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Shared empty/error body for negotiation lists.
class NegotiationListMessage extends StatelessWidget {
  const NegotiationListMessage(
      {super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) =>
      EmptyState(icon: icon, text: text, isError: icon == Icons.cloud_off);
}

final negotiationDateLabel = DateFormat('MMM d, h:mm a');
