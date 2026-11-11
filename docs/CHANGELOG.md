# Changelog

## 2026-11-12 — Phase 1 follow-up corrections

- Initial foundation commit: `c288b12`.
- Corrected the stale foundation changelog entry and recorded this follow-up.
- Ignored `.vscode/` because local editor configuration is machine-specific;
  shared launch configurations can be committed deliberately later with an
  explicit `!` exception.
- Updated the package description to `CTU-G Workspace mobile client for
  Android.`; no dependency or version changed.
- Runtime verification status: **PENDING VERIFICATION**; the existing
  `emulator-5554` was last observed offline. Android Studio UI integration is
  also pending verification.

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
- Checks: dependency resolution, dependency graph, format, analyzer, all tests,
  and debug APK build passed. Runtime remains pending because ADB reported the
  existing emulator offline.
- `.vscode` was an allowed-but-optional entry; the folder was empty before
  creation, and no files were deleted.
- Backend changes: none.
