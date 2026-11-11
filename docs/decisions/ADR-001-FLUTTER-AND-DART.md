# ADR-001 (Mobile Repository): Flutter and Dart

- **Status:** Accepted for the mobile repository foundation.
- **Decision:** Build the Android client with Flutter and Dart.

## Context and alternatives

The project is a new, independent Android client for an existing Django-backed
web system. Alternatives considered were native Android with Kotlin/Compose
and other cross-platform stacks.

## Advantages

- Flutter provides a single UI framework and test tooling for the mobile client.
- The supplied environment has a verified Flutter Android toolchain.
- Flutter's widget and package model supports a small, testable foundation.

## Disadvantages

- Flutter adds Dart and Flutter SDK dependencies to the Android build.
- Native platform integrations may still require Android-specific code.
- A Flutter-based decision does not guarantee future backend compatibility;
  API contracts and mobile authentication remain open.

## Consequences

The Phase 1 app uses Flutter, Dart, Riverpod, and GoRouter. No Kotlin/Compose
application was created; the generated Kotlin `MainActivity` is only the
Flutter Android host.
