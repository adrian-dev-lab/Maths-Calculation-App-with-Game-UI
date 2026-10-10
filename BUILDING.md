# Building Android, Windows, and iOS

Use Flutter 3.44.4 (Dart 3.12.2) for the currently verified setup. Run
`flutter pub get --enforce-lockfile` after cloning, including on a different operating system.
Keep the local dependency directories under `packages/`; see
`packages/BUILD_PATCHES.md` for their build-only changes.

## Android APK

Use JDK 17 and an Android SDK installed through Android Studio. The project pins
AGP 8.13.2, Kotlin 2.3.20, and Gradle 9.2.1. AGP 8 avoids Flutter 3.44's deprecated
AGP 9 compatibility flags; Gradle 9.2.1 embeds the Kotlin 2.2.20 version used by
the Flutter SDK's Gradle build logic.

```powershell
flutter build apk --release --no-pub
```

Output: `build/app/outputs/flutter-apk/app-release.apk`.
For Google Play, use `flutter build appbundle --release --no-pub` instead.

The current release configuration uses the debug signing key for local testing.
Before publishing, choose the final application ID and configure your release
keystore. Keep signing passwords and keystores out of source control.

To inspect Gradle warnings without hiding them:

```powershell
cd android
.\gradlew.bat tasks --all :app:assembleRelease --warning-mode all
```

## Windows EXE

Install Visual Studio with Desktop development with C++, a Windows SDK, and
NuGet on PATH (required by the existing local text-to-speech plugin).

```powershell
flutter build windows --release --no-pub
```

Output: `build/windows/x64/runner/Release/flutter_ui_design.exe`.
Distribute the entire `Release` directory, including its DLLs and `data` folder.
The EXE alone is not a portable Flutter application.

## iOS IPA (requires a Mac)

Windows cannot run Xcode or produce a signed IPA. On macOS, install Xcode and
CocoaPods, then run `flutter doctor -v` and `flutter pub get` in this checkout.
The app targets iOS 13. The Podfile supports the CocoaPods-only local TTS plugin
alongside Flutter's Swift Package Manager integration.

Open `ios/Runner.xcworkspace` in Xcode. Set a unique bundle identifier and your
Apple development team, and configure signing/provisioning for the intended
distribution method. No team or signing identity is selected in this repository.

```sh
flutter build ipa --release
```

Output: `build/ios/ipa/`. The default export is intended for App Store distribution;
use the export method appropriate to your Apple provisioning setup.
An unsigned compile check (`flutter build ios --release --no-codesign`) does not
produce an installable signed IPA.

iOS compilation, signing, and warnings must be verified on the Mac; they cannot
be certified by the Windows build checks.

## Warnings that remain visible

No warning filters or suppression settings have been added.

- AGP 8.13.2 internally uses Gradle's deprecated multi-string dependency notation
  for `lint-gradle` and `aapt2`.
- Flutter 3.44.4 accesses `Task.project` during execution. Recompiling the SDK's
  Gradle plugin can also report its own deprecated API, annotation-target, and
  unchecked-cast warnings. These are SDK sources, not this app's Dart code.
- The TTS plugin retains deprecated audio-focus calls only in its Android API
  24/25 fallback branches. API 26+ already uses `AudioFocusRequest`. Removing the
  fallback would change support for older devices, so it is preserved.

Recheck these warnings when upgrading Flutter/AGP or changing the minimum Android
version. The configuration does not claim to be warning-free on every platform.
