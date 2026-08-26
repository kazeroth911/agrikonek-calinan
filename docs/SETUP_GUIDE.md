# AgriKonek Calinan — Complete Setup Guide

This guide is for a groupmate starting with a new Windows computer. Follow it from top to bottom. It covers Android development with either an Android emulator or a physical Android phone.

> Do not create a new Firebase project. This repository is already connected to the shared `agrikonek-calinan` Firebase project.

## 1. What you need

### Computer

- 64-bit Windows 10 or Windows 11
- A stable internet connection
- At least 15 GB of free storage; allow more if using an Android emulator
- Administrator access for installing development applications
- Preferably 16 GB RAM for Android Studio plus an emulator; use a physical phone if the computer struggles with an emulator

### Accounts

- A [GitHub account](https://github.com/signup)
- A Google account if the team lead gives you Firebase Console access

### Required downloads

Install these applications in this order:

1. [Git for Windows](https://git-scm.com/download/win) — downloads and updates the shared source code.
2. [Flutter SDK](https://docs.flutter.dev/get-started/install/windows/mobile) — builds and runs the application.
3. [Android Studio](https://developer.android.com/studio) — installs the Android SDK, device tools, and emulator.

Optional:

- [Visual Studio Code](https://code.visualstudio.com/download) — a lighter code editor. Android Studio is still needed for the Android SDK and emulator.
- [Firebase CLI](https://firebase.google.com/docs/cli) — only needed for local Firebase emulators or deploying Firebase rules.

You do not need to install Java separately. Use the Java runtime bundled with Android Studio unless `flutter doctor` specifically reports a Java problem.

## 2. Team lead: grant access before setup

The repository owner should complete this section before groupmates clone the project.

### GitHub access

1. Open <https://github.com/Moksxi/agrikonek-calinan>.
2. Select **Settings**.
3. Open **Collaborators** or **Collaborators & teams** under **Access**.
4. Select **Add people**.
5. Enter the groupmate's GitHub username and send the invitation.
6. The groupmate must open GitHub notifications or email and accept the invitation.

If the repository is public, anyone can clone it, but collaborator access is still required to push a branch directly to this repository.

### Firebase access

Groupmates do not need Firebase Console access merely to run the existing client application. Grant access only to members who must inspect Firebase data, add phone-authentication fingerprints, use protected CLI operations, or deploy rules.

1. Open the `agrikonek-calinan` project in the [Firebase Console](https://console.firebase.google.com/).
2. Open **Project settings**.
3. Open **Users and permissions**.
4. Add the groupmate's Google account with the minimum role needed for their task.

Never share a service-account JSON file, private key, or password through chat or GitHub.

## 3. Install and configure Git

1. Download [Git for Windows](https://git-scm.com/download/win).
2. Run the installer.
3. Keep the recommended/default selections unless your instructor specifies otherwise.
4. Finish the installation.
5. Close and reopen PowerShell.
6. Verify Git:

```powershell
git --version
```

Configure the name and email that will appear on future commits:

```powershell
git config --global user.name "YOUR FULL NAME"
git config --global user.email "YOUR GITHUB EMAIL"
```

Confirm them:

```powershell
git config --global user.name
git config --global user.email
```

Use an email connected to your GitHub account, or use your GitHub-provided private `noreply` email if you do not want a personal email shown in commits.

## 4. Install the Flutter SDK

Installing only the Flutter plugin in Android Studio is not enough. The Flutter SDK must also exist on the computer and its `bin` directory must be in the Windows `Path`.

1. Open the official [Flutter installation page for Windows and Android](https://docs.flutter.dev/get-started/install/windows/mobile).
2. Download the latest **stable** Flutter SDK archive.
3. Create a simple folder such as `C:\src`.
4. Extract the archive so the executable is located at:

```text
C:\src\flutter\bin\flutter.bat
```

Avoid extracting Flutter inside `C:\Program Files`, OneDrive, or another folder that requires special permissions.

### Add Flutter to the Windows Path

1. Press the Windows key.
2. Search for **environment variables**.
3. Select **Edit the system environment variables**.
4. Select **Environment Variables**.
5. Under **User variables**, select `Path`, then **Edit**.
6. Select **New** and enter:

```text
C:\src\flutter\bin
```

7. Select **OK** on every open dialog.
8. Close all existing PowerShell and terminal windows.
9. Open a new PowerShell window.
10. Verify Flutter:

```powershell
flutter --version
```

If Windows says `flutter` is not recognized, restart the terminal and check that the Path entry points to the folder containing `flutter.bat`.

## 5. Install Android Studio and the Android tools

1. Download [Android Studio](https://developer.android.com/studio).
2. Run the installer.
3. Keep these components selected:
   - Android Studio
   - Android SDK
   - Android SDK Platform-Tools
   - Android Virtual Device
4. Start Android Studio.
5. Complete the **Standard** setup wizard and allow it to download the recommended SDK components.

### Check the Android SDK

From the Android Studio welcome screen:

1. Select **More Actions**.
2. Select **SDK Manager**.
3. Under **SDK Platforms**, install the latest stable Android SDK platform.
4. Under **SDK Tools**, ensure these are installed:
   - Android SDK Build-Tools
   - Android SDK Command-line Tools (latest)
   - Android SDK Platform-Tools
   - Android Emulator, if using a virtual phone
5. Select **Apply**, accept the licenses, and wait for installation to finish.

### Optional Android Studio Flutter plugin

Install this if you want to edit Flutter code in Android Studio:

1. Open **Settings > Plugins**.
2. Search for **Flutter**.
3. Select **Install**.
4. Accept installation of the Dart plugin when prompted.
5. Restart Android Studio.

## 6. Accept Android licenses and check the computer

Open a new PowerShell window and run:

```powershell
flutter doctor --android-licenses
```

Read each license and enter `y` to accept it when appropriate. Then run:

```powershell
flutter doctor
```

Fix any red error under **Flutter** or **Android toolchain** before continuing.

If `flutter doctor` reports that Visual Studio for Windows or Chrome is missing, that can be ignored when the team is building only the Android application. **Visual Studio** and **Visual Studio Code** are different applications.

## 7. Download the AgriKonek project

1. Accept the GitHub collaborator invitation, if one was sent.
2. Open File Explorer and create or choose a development folder, for example:

```text
C:\Users\YOUR_WINDOWS_NAME\Documents\Projects
```

3. Open that folder.
4. Click the File Explorer address bar, type `powershell`, and press Enter.
5. Clone the repository:

```powershell
git clone https://github.com/Moksxi/agrikonek-calinan.git
```

6. Enter the project folder:

```powershell
cd agrikonek-calinan
```

7. Confirm that the project was downloaded:

```powershell
git status
```

The expected result should say that you are on `main` and the working tree is clean.

### Open the correct folder in Android Studio

1. In Android Studio, select **Open**.
2. Choose the top-level `agrikonek-calinan` folder.
3. Do not open only the nested `android` folder.
4. Wait for indexing and Android/Gradle synchronization to finish.

## 8. Restore project dependencies

In PowerShell, make sure the prompt is inside the `agrikonek-calinan` folder, then run:

```powershell
flutter pub get
```

This downloads the Flutter packages listed in `pubspec.yaml`. It also recreates local generated files that are intentionally excluded from GitHub.

Do not run `flutter create` and do not replace `pubspec.yaml`, `firebase_options.dart`, or `google-services.json`.

## 9. Choose a device

Use either an Android emulator or a physical Android phone. You do not need both.

### Option A — Android emulator

1. Open Android Studio.
2. From the welcome screen, select **More Actions > Virtual Device Manager**. If a project is open, use **View > Tool Windows > Device Manager**.
3. Select **Create Device**.
4. Choose a common phone profile such as a Pixel device, then select **Next**.
5. Choose a recent stable system image with **Google APIs** or the **Google Play** logo.
6. Select **Download** if the image is not installed.
7. After the download, select the image, then **Next > Finish**.
8. In Device Manager, select the triangular **Play** button beside the new virtual phone.
9. Wait until the Android home screen is fully visible.

If the emulator is very slow, close other applications, enable CPU virtualization in the computer firmware if supported, or use a physical Android phone.

### Option B — physical Android phone through USB

On the phone:

1. Open **Settings > About phone**.
2. Tap **Build number** seven times until developer mode is enabled. The exact menu name can vary by phone manufacturer.
3. Return to Settings and open **Developer options**.
4. Enable **USB debugging**.
5. Connect the phone to the computer using a USB data cable, not a charging-only cable.
6. Unlock the phone.
7. Accept the **Allow USB debugging** prompt and, if appropriate, select **Always allow from this computer**.

On Windows, install the manufacturer's USB driver if the phone is not detected. Android's official [hardware-device guide](https://developer.android.com/studio/run/device) links to supported OEM drivers.

## 10. Run AgriKonek for the first time

From the project folder, list available devices:

```powershell
flutter devices
```

If exactly one Android device appears, run:

```powershell
flutter run
```

If several devices appear, copy the desired device ID and run:

```powershell
flutter run -d DEVICE_ID
```

The first Android build can take several minutes because Gradle and Android dependencies must download. Keep the internet connection active and do not close the terminal.

While the app is running in the terminal:

- Press `r` for hot reload after a small code change.
- Press `R` for a full hot restart.
- Press `q` to stop the app.

The normal command uses the shared live Firebase project. The checked-in client configuration is already set up; a groupmate should not generate a replacement Firebase project.

## 11. Optional: use local Firebase emulators

Skip this section unless you are developing Firebase behavior without touching live data.

### Install the Firebase CLI

For a beginner on Windows, use the standalone Windows download described in the official [Firebase CLI documentation](https://firebase.google.com/docs/cli). Developers who already use Node.js can instead install [Node.js LTS](https://nodejs.org/en/download) and run:

```powershell
npm install -g firebase-tools
```

Confirm installation:

```powershell
firebase --version
```

If a protected Firebase operation requires authentication:

```powershell
firebase login
```

### Start the emulators

Open PowerShell in the project folder and run:

```powershell
firebase emulators:start --only auth,firestore,storage
```

Leave that terminal open. Open a second PowerShell window in the same project folder and run:

```powershell
flutter run --dart-define=USE_EMULATORS=true
```

This project uses Auth port `9099`, Firestore port `8080`, and Storage port `9199`. An Android emulator reaches the Windows host through `10.0.2.2`; that mapping is already handled by the app.

Emulator data is separate from live Firebase data.

## 12. Verify the project before editing

Run both checks from the project folder:

```powershell
flutter analyze
flutter test
```

At the time this guide was published, static analysis reported no issues and all 49 tests passed.

## 13. Team Git workflow

Do not make shared changes directly on `main`. Use `develop` and a separate feature branch for each task.

### Start a new task

```powershell
git switch develop
git pull origin develop
git switch -c feature/YOUR-NAME-SHORT-TASK
```

Example:

```powershell
git switch -c feature/ana-profile-photo
```

Use lowercase words and hyphens in the branch name.

### Before saving your work to GitHub

Format and verify the project:

```powershell
dart format .
flutter analyze
flutter test
git status
```

Review the files listed by `git status`. Do not commit passwords, `.env` files, service-account JSON files, keystores, build folders, or unrelated school files.

Commit and push:

```powershell
git add .
git commit -m "describe the change clearly"
git push -u origin feature/YOUR-NAME-SHORT-TASK
```

Then open the GitHub link printed by Git, create a pull request, and select `develop` as the base branch. Ask at least one groupmate to review it before merging.

Do not let two groupmates work on the same branch. Each person should use a separate feature branch.

### Get the team's newest changes later

Before starting another task:

```powershell
git switch develop
git pull origin develop
```

## 14. Phone OTP setup for another developer's computer

Email/password login can work without a developer-specific Android certificate. Phone authentication may require the SHA-1 or SHA-256 fingerprint of the debug signing key created on that groupmate's computer.

After the first Android build, the groupmate can obtain the fingerprints with:

```powershell
cd android
.\gradlew signingReport
cd ..
```

Copy the `SHA1` and `SHA-256` values under the debug variant. A team member with Firebase Console access should add them under:

**Firebase Console > Project settings > Your apps > Android app > Add fingerprint**

Do not create a second Android app entry unless the package name changes. The package name for this project is `com.agrikonek.agrikonek_calinan`.

## 15. Common problems

### `git` is not recognized

- Finish installing Git for Windows.
- Close and reopen PowerShell.
- Run `git --version` again.

### `flutter` is not recognized

- Confirm that `C:\src\flutter\bin` exists.
- Add that exact folder to the user `Path`.
- Close and reopen PowerShell.

### Flutter reports an Android toolchain error

- Open Android Studio's SDK Manager.
- Install Android SDK Command-line Tools, Platform-Tools, and Build-Tools.
- Run `flutter doctor --android-licenses`.
- Run `flutter doctor` again.

### `flutter devices` shows no Android device

- For an emulator, wait until the Android home screen appears.
- For a phone, unlock it and accept the USB debugging prompt.
- Try another USB data cable or port.
- Install the phone manufacturer's Windows USB driver.
- Run `flutter devices` again.

### The first Gradle build fails while downloading

Check the internet connection, then run:

```powershell
flutter clean
flutter pub get
flutter run
```

`flutter clean` removes generated build output; it does not remove source code.

### Firebase says permission denied

- Confirm that the app user is signed in.
- Confirm that the requested data belongs to the signed-in user or role allowed by the Firebase rules.
- Ask the team lead before changing `firestore.rules` or `storage.rules`.
- Do not solve permission errors by making the database publicly readable or writable.

### Phone OTP does not send or verify

- Confirm that the computer's debug SHA-1 and SHA-256 fingerprints were added to the existing Android app in Firebase.
- Confirm that Phone authentication is enabled in the shared Firebase project.
- Check device internet access and Firebase usage limits.

### GitHub rejects a push

- Confirm that the collaborator invitation was accepted.
- Confirm that the branch is your own feature branch, not `main`.
- Sign in when Git Credential Manager opens.
- Ask the repository owner to confirm collaborator access.

### You accidentally edited the wrong branch

Do not delete or reset files. Stop and ask a groupmate to help move the changes safely to a feature branch.

## 16. Final setup checklist

A groupmate is ready when every box below can be checked:

- [ ] GitHub invitation accepted
- [ ] `git --version` works
- [ ] `flutter --version` works
- [ ] Android Studio and the Android SDK are installed
- [ ] `flutter doctor` has no blocking Flutter or Android errors
- [ ] Repository cloned successfully
- [ ] `flutter pub get` completes
- [ ] Emulator or physical phone appears in `flutter devices`
- [ ] `flutter run` opens AgriKonek
- [ ] `flutter analyze` reports no issues
- [ ] `flutter test` passes
- [ ] Groupmate knows to work from `develop` using a personal feature branch

## Official references

- [Flutter: install for Windows and Android](https://docs.flutter.dev/get-started/install/windows/mobile)
- [Flutter: set up Android development](https://docs.flutter.dev/platform-integration/android/setup)
- [Android Studio installation](https://developer.android.com/studio/install.html)
- [Android Studio Device Manager](https://developer.android.com/studio/run/managing-avds)
- [Android physical-device setup](https://developer.android.com/studio/run/device)
- [Git for Windows](https://git-scm.com/download/win)
- [GitHub: cloning and pulling repositories](https://docs.github.com/en/get-started/using-git/getting-changes-from-a-remote-repository)
- [GitHub: repository collaborators](https://docs.github.com/en/repositories/creating-and-managing-repositories/access-to-repositories)
- [Firebase CLI](https://firebase.google.com/docs/cli)
