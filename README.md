# CTU-G Mobile App

Independent Android application for CTU-G. This repository contains the mobile
client foundation only; the existing web application and Django backend remain
in the sibling `C:\Users\Janrey\CTU-G_Workspace` repository.

## Current phase

Phase 1 establishes the Flutter project, environment configuration validation,
a single startup screen, routing, Material 3 theme, tests, and architecture
documentation. There is no authentication, networking, data persistence, or
business feature implementation.

## Stack and verified environment

- Flutter 3.47.9 stable; Dart 3.13.7.
- Android SDK 36.0.0; Flutter doctor reports an Android toolchain and the
  Android Studio bundled Java 25.0.3 runtime.
- Git 2.52.0; Android Gradle Plugin 9.1.0; Gradle 9.3.1.
- `flutter doctor -v` reported the Android toolchain usable. Its Visual Studio
  warning concerns Windows desktop development, not this Android-only app.
- Android Studio project integration has not been verified.
- Repository location: `C:\Users\Janrey\CTU-G_Workspace Mobile App`.

## Prerequisites

Install Flutter with Android support, Android SDK platform/build tools, and
Git. Use a Java runtime supported by the installed Android Gradle Plugin and
Gradle; Flutter currently selects the Android Studio bundled JDK. See
[Development Environment](docs/setup/DEVELOPMENT_ENVIRONMENT.md) and
[Android Studio Setup](docs/setup/ANDROID_STUDIO_SETUP.md) for verified
environment details and steps not executed here. In the verified environment,
Flutter was invoked as
`C:\Users\Janrey\develop\flutter\bin\flutter.bat`; PATH was not changed.

## Dependencies

The app's direct state-management and routing dependencies are
`flutter_riverpod` 3.5.0 and `go_router` 18.1.4. The generated Flutter template's
`cupertino_icons` 1.0.9 dependency and SDK-provided `flutter_test` are retained.
`flutter_lints` 6.0.0 remains enabled. See `pubspec.lock` for the full resolved
dependency graph.

## Environment configuration

Configuration is supplied as Dart compile-time defines. The app does not load
JSON configuration from disk. Copy an example to a local ignored file, then run:

```powershell
Copy-Item env\dev.example.json env\dev.json
flutter run -d <deviceId> --dart-define-from-file=env\dev.json
```

The keys are `APP_ENV` (`development`, `test`, or `production`),
`API_BASE_URL` (absolute HTTP(S) URL with a host and no user-info, query, or
fragment), and optional `LOG_LEVEL` (`debug`, `info`, `warning`, or `error`;
defaults to `info`). The URL is normalized to end with `/`. Production requires
HTTPS and rejects hosts ending in `.invalid`. The production example deliberately
uses `example.invalid` and therefore fails validation until replaced with an
appropriate URL.

Missing or invalid required values fail fast with `AppConfigException` during
startup. The API URL is not shown on screen. Example JSON files document the
schema; they are not read at runtime. Local `env/*.json` files are ignored by
Git, while `*.example.json` files are tracked.

## Install, run, and test

From the repository directory:

```powershell
flutter pub get
flutter run -d <deviceId> --dart-define-from-file=env\dev.json
flutter test
```

`env\dev.json` must first be copied from `env\dev.example.json` and edited if
needed. Android debug APK build:

```powershell
flutter build apk --debug
```

## Project structure

- `lib/app/`: app root, router, provider, startup screen, and theme.
- `lib/core/config/`: validated environment and app configuration.
- `env/`: tracked example configuration files only.
- `test/`: configuration, root-widget, and router tests.
- `android/`: Flutter-generated Android project and Gradle wrapper.
- `docs/`: architecture, decisions, environment setup, and test evidence.

See [Project Structure](docs/architecture/PROJECT_STRUCTURE.md) for the
complete layer map and conventions.

## Known limitations and permission note

- There is no authentication, network client, HTTP dependency, backend call,
  local database, or product feature in this phase.
- The main Android manifest contains no `INTERNET` permission and no
  cleartext/network-security configuration. The Flutter-generated debug and
  profile manifests contain the template's development `INTERNET` permission;
  those files were left unchanged under an explicitly approved Phase 1
  exception. No networking code exists. The built release manifest was not
  inspected, so its permission status is **not verified**.
- The pre-existing `Medium_Phone` emulator's debug runtime was verified:
  `flutter run -d emulator-5554 --dart-define-from-file=env/dev.json
  --no-resident` built, installed, and launched successfully; the app process
  remained present with the same PID after 30 seconds, and the captured logcat
  had none of the checked Flutter/app crash markers. The user had previously
  confirmed the screen showed “CTU-G”, “App initialized”, and “development”
  with the debug banner; the agent did not visually inspect the screen.
- Android Studio project integration remains unverified. The built release
  manifest's `INTERNET` permission status remains unverified.
- The starter theme is not final branding. Production URLs and device
  certificate strategy remain undecided.

Future authentication, REST integration, permissions, and business features
belong to separately authorized phases. They are not included here.
