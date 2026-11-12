# Changelog

## 2026-11-12 — Phase 1 runtime verification

- Verified a debug build, installation, and launch on the existing
  `Medium_Phone` emulator with the development configuration. The app process
  remained stable for 30 seconds, and the captured logcat contained none of
  the checked crash/configuration markers. The user had previously confirmed
  the startup screen text; the agent did not visually inspect it.
- Documented the user's resolution for the emulator initially appearing
  offline in ADB. See [Development Environment](setup/DEVELOPMENT_ENVIRONMENT.md)
  and [Phase 1 Test Report](testing/PHASE-1-TEST-REPORT.md) for attribution and
  evidence.
- The local DevTools options ignore rule was committed separately as
  `23360a8` (`Ignore local DevTools options file`).
- Android Studio UI integration and the built release manifest permission
  status remain unverified.

## 2026-11-12 — Phase 1 follow-up corrections

- Initial foundation commit: `c288b12`.
- Corrected the stale foundation changelog entry and recorded this follow-up.
- Ignored `.vscode/` because local editor configuration is machine-specific;
  shared launch configurations can be committed deliberately later with an
  explicit `!` exception.
- Updated the package description to `CTU-G Workspace mobile client for
  Android.`; no dependency or version changed.
- At the time of this follow-up, runtime verification was still pending because
  the existing `emulator-5554` was last observed offline. The later runtime
  verification is recorded above. Android Studio UI integration remains
  unverified.

## 2026-11-12 — Phase 1 foundation

- Created an independent Android Flutter project `ctug_mobile` with
  applicationId/namespace `com.ctug.ctug_mobile`.
- Added compile-time environment validation, Riverpod configuration provider,
  GoRouter startup route, Material 3 theme, and the CTU-G initialized screen.
- Added three environment examples and 17 configuration/widget/router tests.
- Added Git ignore and line-ending rules; set repository-local Git author.
- Changed only the main Android manifest label to `CTU-G`.
- Documented that untouched Flutter-generated debug/profile manifests contain
  the template `INTERNET` permission (approved Phase 1 exception); no networking
  code or HTTP package dependency exists. Release manifest permission status
  was not verified.
- Added architecture, backend snapshot baseline, setup, ADR, and test-report
  documentation.
- Checks at that point: dependency resolution, dependency graph, format,
  analyzer, all tests, and debug APK build passed. Runtime had not yet been
  verified because ADB reported the existing emulator offline.
- `.vscode` was an allowed-but-optional entry; the folder was empty before
  creation, and no files were deleted.
- Backend changes: none.
