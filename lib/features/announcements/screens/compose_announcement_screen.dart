import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/announcement.dart';
import '../../../models/profile.dart';
import '../../admin/providers/profiling_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/announcement_providers.dart';

/// Researcher-admin writes a notice and chooses who receives it.
class ComposeAnnouncementScreen extends ConsumerStatefulWidget {
  const ComposeAnnouncementScreen({super.key});

  @override
  ConsumerState<ComposeAnnouncementScreen> createState() =>
      _ComposeAnnouncementScreenState();
}

class _ComposeAnnouncementScreenState
    extends ConsumerState<ComposeAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  AnnouncementAudience _audience = AnnouncementAudience.all;
  String? _barangay;
  final Set<String> _selected = {};
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  List<Profile> _recipients(List<Profile> profiles, String uid) =>
      Announcement.pickRecipients(
        profiles: profiles,
        audience: _audience,
        senderId: uid,
        barangay: _barangay,
        selectedIds: _selected,
      );

  Future<void> _send(List<Profile> recipients) async {
    if (!_formKey.currentState!.validate()) return;
    if (recipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Choose at least one recipient.')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send announcement?'),
        content: Text(
            'This sends "${_title.text.trim()}" to ${recipients.length} '
            '${recipients.length == 1 ? 'person' : 'people'}, '
            'with a phone notification. It cannot be unsent.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('SEND')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    final name =
        ref.read(currentProfileProvider).valueOrNull?.fullName ?? 'Researcher';

    setState(() => _sending = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(announcementRepositoryProvider).send(
            senderId: uid,
            senderName: name,
            title: _title.text.trim(),
            body: _body.text.trim(),
            audience: _audience,
            barangay: _barangay,
            recipientIds: recipients.map((p) => p.userId).toList(),
          );
      messenger.showSnackBar(SnackBar(
          content: Text('Announcement sent to ${recipients.length}.')));
      navigator.pop();
    } catch (error) {
      messenger.showSnackBar(
          SnackBar(content: Text('Could not send: $error')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authStateProvider).valueOrNull?.uid ?? '';
    final profilesAsync = ref.watch(allProfilesProvider);
    final profiles = profilesAsync.valueOrNull ?? const <Profile>[];
    final recipients = _recipients(profiles, uid);
    final everyone = Announcement.pickRecipients(
        profiles: profiles,
        audience: AnnouncementAudience.all,
        senderId: uid);

    return Scaffold(
      appBar: AppBar(title: const Text('New announcement')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              maxLength: Announcement.maxTitleLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title / Ulohan',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _body,
              maxLength: Announcement.maxBodyLength,
              minLines: 4,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Message / Mensahe',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a message' : null,
            ),
            const SizedBox(height: 16),
            Text('Send to', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<AnnouncementAudience>(
              segments: const [
                ButtonSegment(
                    value: AnnouncementAudience.all, label: Text('Everyone')),
                ButtonSegment(
                    value: AnnouncementAudience.barangay,
                    label: Text('Barangay')),
                ButtonSegment(
                    value: AnnouncementAudience.selected,
                    label: Text('Choose')),
              ],
              selected: {_audience},
              onSelectionChanged: (s) => setState(() => _audience = s.first),
            ),
            const SizedBox(height: 12),
            if (_audience == AnnouncementAudience.barangay)
              DropdownButtonFormField<String>(
                initialValue: _barangay,
                decoration: const InputDecoration(
                  labelText: 'Barangay',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final b in AppConstants.calinanBarangays)
                    DropdownMenuItem(value: b, child: Text(b)),
                ],
                onChanged: (v) => setState(() => _barangay = v),
                validator: (v) => (_audience == AnnouncementAudience.barangay &&
                        (v == null || v.isEmpty))
                    ? 'Choose a barangay'
                    : null,
              ),
            if (_audience == AnnouncementAudience.selected)
              if (profilesAsync.isLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Card(
                  child: Column(
                    children: [
                      for (final p in everyone)
                        CheckboxListTile(
                          value: _selected.contains(p.userId),
                          title: Text(p.fullName),
                          subtitle: Text(p.barangay),
                          onChanged: (on) => setState(() {
                            if (on == true) {
                              _selected.add(p.userId);
                            } else {
                              _selected.remove(p.userId);
                            }
                          }),
                        ),
                    ],
                  ),
                ),
            const SizedBox(height: 12),
            Text(
              profilesAsync.hasError
                  ? 'Could not load profiles: ${profilesAsync.error}'
                  : 'Will reach ${recipients.length} '
                      '${recipients.length == 1 ? 'person' : 'people'}. '
                      'Researcher accounts are never included.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _sending ? null : () => _send(recipients),
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              label: const Text('Send announcement'),
            ),
          ],
        ),
      ),
    );
  }
}
