import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_language.dart';

/// App settings. For now: the display language.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Settings', 'Mga Setting'))),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              context.tr('Language', 'Pinulongan'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          RadioGroup<AppLanguage>(
            groupValue: current,
            onChanged: (value) {
              if (value != null) ref.read(languageProvider.notifier).set(value);
            },
            child: Column(
              children: [
                for (final language in AppLanguage.values)
                  RadioListTile<AppLanguage>(
                    value: language,
                    title: Text(language.displayName),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              context.tr(
                  'Phone notifications also arrive in this language.',
                  'Ang mga pahibalo sa cellphone moabot usab niini nga pinulongan.'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small language switch for screens shown before sign-in.
class LanguageMenuButton extends ConsumerWidget {
  const LanguageMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(languageProvider);
    return PopupMenuButton<AppLanguage>(
      tooltip: context.tr('Language', 'Pinulongan'),
      icon: const Icon(Icons.translate),
      initialValue: current,
      onSelected: (value) => ref.read(languageProvider.notifier).set(value),
      itemBuilder: (_) => [
        for (final language in AppLanguage.values)
          PopupMenuItem(value: language, child: Text(language.displayName)),
      ],
    );
  }
}
