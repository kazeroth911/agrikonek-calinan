import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_language.dart';

/// Shown on offers, barters, listings and chats whose other party has
/// hidden their profile.
class ProfileUnavailableBanner extends StatelessWidget {
  const ProfileUnavailableBanner({super.key, this.detail});

  final String? detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      child: ListTile(
        leading: Icon(Icons.visibility_off_outlined, color: scheme.outline),
        title: Text(context.tr(AppConstants.profileUnavailable,
            AppConstants.profileUnavailableCeb)),
        subtitle: detail == null ? null : Text(detail!),
      ),
    );
  }
}
