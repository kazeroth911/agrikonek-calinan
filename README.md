# AgriKonek Calinan

AgriKonek Calinan is an Android marketplace and connectivity application for pre-profiled smallholder farmers in Calinan District, Davao City. It supports farmer profiles, produce listings, cash offers, barter proposals, notifications, and role-based access.

## New developer setup

Setting up for the first time? Follow the **[complete Windows and Android setup guide](docs/SETUP_GUIDE.md)**. How notifications work, and how to deploy and test them: **[docs/NOTIFICATIONS.md](docs/NOTIFICATIONS.md)**. Running all automated tests, including the security-rule tests: **[docs/TESTING.md](docs/TESTING.md)**. It covers every required download, GitHub access, Flutter and Android Studio installation, emulator and physical-phone setup, Firebase, the first run, troubleshooting, and the team Git workflow.

## Technology

- Flutter and Dart
- Firebase Authentication
- Cloud Firestore
- Cloud Storage
- Firebase Cloud Messaging
- Riverpod state management

## Requirements

- Flutter with Dart 3.0 or newer
- Android Studio or another configured Android development environment
- An Android emulator or physical Android device
- Firebase CLI, only when using local Firebase emulators or deploying rules

## Run the app

From the project directory:

```powershell
flutter pub get
flutter run
```

If Flutter finds more than one device:

```powershell
flutter devices
flutter run -d DEVICE_ID
```

The checked-in Firebase client configuration points to the AgriKonek Calinan Firebase project. Firebase client configuration identifies the project but does not replace Firestore and Storage security rules.

## Use Firebase emulators

Start the configured Auth, Firestore, and Storage emulators:

```powershell
firebase emulators:start --only auth,firestore,storage
```

Run the Android app against them:

```powershell
flutter run --dart-define=USE_EMULATORS=true
```

Configured ports are Auth `9099`, Firestore `8080`, and Storage `9199`. Android emulators connect to the host through `10.0.2.2`.

## Quality checks

```powershell
flutter analyze
flutter test
```

## Project structure

- `lib/features/` — screens, widgets, and Riverpod providers grouped by feature
- `lib/models/` — application data models
- `lib/services/` — Firebase repositories and supporting services
- `test/` — model, negotiation-logic, service, and widget tests
- `firestore.rules` — Firestore authorization rules
- `storage.rules` — Cloud Storage authorization rules
- `docs/` — capstone and project documentation

## Documentation

See [docs/CAPSTONE_STUDY_GUIDE.md](docs/CAPSTONE_STUDY_GUIDE.md) for the capstone study and oral-defense guide.

## Security

Never commit Firebase Admin SDK service-account files, private keys, signing keystores, passwords, or `.env` files. Review and test `firestore.rules` and `storage.rules` before deploying changes.
