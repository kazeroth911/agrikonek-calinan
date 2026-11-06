import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/announcement.dart';
import '../../../models/app_notification.dart';
import '../../../services/announcement_repository.dart';
import '../../auth/providers/auth_providers.dart';

final announcementRepositoryProvider = Provider<AnnouncementRepository>(
    (ref) => AnnouncementRepository(ref.watch(firestoreProvider)));

/// Sent history for the researcher-admin screen.
final sentAnnouncementsProvider = StreamProvider<List<Announcement>>((ref) {
  // Re-subscribe on account switch so a cached permission error is not reused.
  ref.watch(authStateProvider);
  return ref.watch(announcementRepositoryProvider).watchAll();
});

/// One notification record, for opening an announcement from a push.
final notificationByIdProvider =
    StreamProvider.family<AppNotification?, String>((ref, notificationId) {
  ref.watch(authStateProvider);
  return ref.watch(notificationRepositoryProvider).watchOne(notificationId);
});
