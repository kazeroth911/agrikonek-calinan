import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/l10n/app_language.dart';
import 'firebase_options.dart';
import 'services/admin_account_service.dart';
import 'services/push_notification_service.dart';

const bool kUseEmulators = bool.fromEnvironment(
  'USE_EMULATORS',
  defaultValue: false,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Offline-cached feed (Table 3.6): listings, bids and chats already
  // seen stay readable without signal and sync when it returns. On by
  // default on Android; set explicitly, with a cap for low-storage phones.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: 50 * 1024 * 1024, // 50 MB
  );

  if (kUseEmulators && !kReleaseMode) {
    // 10.0.2.2 is the laptop as seen from the Android emulator. For a real
    // phone, pass the laptop's Wi-Fi address with --dart-define=EMULATOR_HOST=.
    const host =
        String.fromEnvironment('EMULATOR_HOST', defaultValue: '10.0.2.2');

    await FirebaseAuth.instance.useAuthEmulator(
      host,
      9099,
    );
    // Farmer logins made by the profiling form go to the emulator too.
    AdminAccountService.authEmulatorHost = host;

    FirebaseFirestore.instance.useFirestoreEmulator(
      host,
      8080,
    );

    await FirebaseStorage.instance.useStorageEmulator(
      host,
      9199,
    );
  }

  // Loaded before the first frame so the saved language shows at once.
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const AgriKonekApp(),
    ),
  );

  await PushNotificationService.instance.initialize();
}
