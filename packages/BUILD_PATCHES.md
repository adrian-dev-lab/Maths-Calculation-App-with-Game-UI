# Local dependency build patches

The application uses local Android subprojects from `shared_preferences_android`
2.4.26 and `sqflite_android` 2.4.3 through `android/settings.gradle.kts` project
directory overrides. Dart dependencies still come from Pub and are pinned in
`pubspec.lock`. Runtime behavior is unchanged. Android sources/tests and licenses
are retained; Dart code, examples, and generated caches are not vendored.

- `shared_preferences_android`: remove the obsolete manifest `package` attribute
  (the namespace already exists) and a redundant Kotlin non-null assertion.
- `sqflite_android`: replace deprecated Groovy property assignments and use `lint`
  instead of `lintOptions`.
- Existing local `flutter_tts`: modernize Gradle property assignments and Kotlin
  compiler configuration, remove redundant Kotlin non-null assertions and the obsolete manifest
  `package` attribute, and align the iOS pod with the app's iOS 13 minimum and
  Swift 5 language mode.

Flutter 3.44 applies the Kotlin Android plugin automatically to migrated plugins;
the app and local plugins therefore do not apply it explicitly.

When updating dependencies, recheck these small build patches against upstream
before removing the overrides. Update these Android copies together with the
corresponding Pub versions so native and Dart interfaces stay aligned.
Do not edit the global Pub cache.
