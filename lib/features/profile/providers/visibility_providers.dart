import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';

/// IDs of every hidden profile, live. Screens use it to drop hidden
/// farmers' listings from the marketplace and to show
/// "This profile is unavailable." on their offers and chats.
final hiddenProfileIdsProvider = StreamProvider<Set<String>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const <String>{});
  return ref.watch(profileRepositoryProvider).watchHiddenIds();
});

/// True when [uid] is hidden. While the list is still loading this is
/// false, so screens never flash "unavailable" for a normal profile.
final isProfileHiddenProvider = Provider.family<bool, String>((ref, uid) {
  final hidden = ref.watch(hiddenProfileIdsProvider).valueOrNull;
  return hidden?.contains(uid) ?? false;
});
