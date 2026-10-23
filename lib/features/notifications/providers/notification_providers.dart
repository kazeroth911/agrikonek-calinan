import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/app_notification.dart';
import '../../auth/providers/auth_providers.dart';

/// Reads only notifications addressed to the currently authenticated user.
final myNotificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const <AppNotification>[]);
  return ref.watch(notificationRepositoryProvider).watchMine(uid);
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(myNotificationsProvider).valueOrNull;
  if (notifications == null) return 0;
  return notifications.where((notification) => !notification.read).length;
});
