import 'package:flutter/material.dart';

import '../../../models/profile.dart';

/// Shows a profile's verification level as Table 3.4 of the paper words
/// it: level 1 "Visited by researchers", level 2 "Cooperative-confirmed".
/// Nothing is shown when no level is recorded.
class VerificationBadge extends StatelessWidget {
  const VerificationBadge({super.key, required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (IconData icon, String label, Color bg, Color fg) = switch (level) {
      Profile.levelCooperativeConfirmed => (
          Icons.verified,
          'Cooperative-confirmed / Gikumpirma sa kooperatiba',
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
        ),
      Profile.levelVisited => (
          Icons.how_to_reg,
          'Visited by researchers / Gibisita sa mga researcher',
          scheme.secondaryContainer,
          scheme.onSecondaryContainer,
        ),
      _ => (Icons.help_outline, '', scheme.surface, scheme.onSurface),
    };
    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: fg, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
