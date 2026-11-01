import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_language.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/cooperative.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/profiling_providers.dart';

/// Researcher-admin list of partner cooperatives and associations
/// (Figure 3.4). A farmer's profile refers to one only when the farmer
/// agreed to cooperative confirmation (C5).
class CooperativesScreen extends ConsumerWidget {
  const CooperativesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cooperatives = ref.watch(cooperativesProvider);
    final profiles = ref.watch(_memberCountsProvider);

    return Scaffold(
      appBar: AppBar(
          title: Text(context.tr('Cooperatives', 'Mga Kooperatiba'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddCooperativeDialog(context, ref),
        icon: const Icon(Icons.add_business_outlined),
        label: Text(context.tr('Add', 'Idugang')),
      ),
      body: cooperatives.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
            icon: Icons.cloud_off,
            isError: true,
            text: 'Could not load cooperatives.\n$e'),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.groups_outlined,
              text: 'No cooperatives yet.\n\nAdd the partner cooperative or '
                  'association named in the MOU, so that confirmed members '
                  'can be linked to it.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final c = list[i];
              final members = profiles[c.cooperativeId] ?? 0;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.groups_outlined),
                  title: Text(c.name),
                  subtitle: Text([
                    if (c.barangay != null) c.barangay!,
                    '$members linked ${members == 1 ? 'profile' : 'profiles'}',
                  ].join(' · ')),
                  trailing: IconButton(
                    tooltip: 'Rename',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _rename(context, ref, c),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _rename(
      BuildContext context, WidgetRef ref, Cooperative c) async {
    final controller = TextEditingController(text: c.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename cooperative'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: Cooperative.maxNameLength,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('SAVE')),
        ],
      ),
    );
    if (name == null || name.isEmpty || name == c.name || !context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(cooperativeRepositoryProvider).rename(c.cooperativeId, name);
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('Could not rename: $error')));
    }
  }
}

/// How many profiles each cooperative is linked to (admins only).
final _memberCountsProvider = Provider<Map<String, int>>((ref) {
  final profiles = ref.watch(allProfilesProvider).valueOrNull ?? const [];
  final counts = <String, int>{};
  for (final p in profiles) {
    final id = p.cooperativeId;
    if (id != null && !p.isClaimed) counts[id] = (counts[id] ?? 0) + 1;
  }
  return counts;
});

/// Asks for a cooperative's name and barangay and saves it.
/// Returns the new cooperative's ID, or null if cancelled.
Future<String?> showAddCooperativeDialog(BuildContext context, WidgetRef ref,
    {String? barangay}) async {
  final nameController = TextEditingController();
  String? chosenBarangay = barangay;
  final result = await showDialog<(String, String?)>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Add a cooperative'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              maxLength: Cooperative.maxNameLength,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Registered name *'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: chosenBarangay,
              isExpanded: true,
              decoration:
                  const InputDecoration(labelText: 'Barangay (optional)'),
              items: [
                for (final b in AppConstants.calinanBarangays)
                  DropdownMenuItem(value: b, child: Text(b)),
              ],
              onChanged: (v) => setState(() => chosenBarangay = v),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(context).pop((name, chosenBarangay));
              }
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    ),
  );
  if (result == null || !context.mounted) return null;
  final messenger = ScaffoldMessenger.of(context);
  try {
    return await ref.read(cooperativeRepositoryProvider).add(Cooperative(
          cooperativeId: '',
          name: result.$1,
          barangay: result.$2,
        ));
  } catch (error) {
    messenger.showSnackBar(
        SnackBar(content: Text('Could not add the cooperative: $error')));
    return null;
  }
}
