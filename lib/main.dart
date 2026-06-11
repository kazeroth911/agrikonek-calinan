import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app.dart';
import 'firebase_options.dart';

/// Set to true while developing to point the app at the local
/// Firebase Emulator Suite instead of the live asia-southeast1 project.
/// Run: firebase emulators:start --only auth,firestore,storage
const bool kUseEmulators = bool.fromEnvironment('USE_EMULATORS', defaultValue: false);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kUseEmulators && !kReleaseMode) {
    // 10.0.2.2 is the Android emulator's alias for the host machine.
    const host = '10.0.2.2';
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  }

  runApp(const ProviderScope(child: AgriKonekApp()));
}
