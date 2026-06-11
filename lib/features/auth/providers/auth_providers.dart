import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/profile.dart';
import '../../../services/admin_account_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/notification_repository.dart';
import '../../../services/profile_repository.dart';
import '../../../services/storage_service.dart';

// ---- SDK singletons -------------------------------------------------------
final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// ---- Services -------------------------------------------------------------
final authServiceProvider = Provider<AuthService>(
    (ref) => AuthService(ref.watch(firebaseAuthProvider)));
final profileRepositoryProvider = Provider<ProfileRepository>(
    (ref) => ProfileRepository(ref.watch(firestoreProvider)));
final adminAccountServiceProvider =
    Provider<AdminAccountService>((ref) => AdminAccountService());
final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());
final notificationRepositoryProvider = Provider<NotificationRepository>(
    (ref) => NotificationRepository(ref.watch(firestoreProvider)));

// ---- Auth state -----------------------------------------------------------
final authStateProvider = StreamProvider<User?>(
    (ref) => ref.watch(authServiceProvider).authStateChanges);

final currentProfileProvider = StreamProvider<Profile?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return ref.watch(profileRepositoryProvider).watchProfile(user.uid);
});
