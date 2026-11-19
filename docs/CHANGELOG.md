# Changelog

## 2026-11-19 — Sign-up and email verification

- **VERIFIED:** Added the Student-only, display-only School Information note
  (`7eb70d9`). It adds no form inputs and does not change the nine-field
  registration request.
- **VERIFIED:** Changed the sign-up button label to `Proceed Email
  Verification` (`e3b9163`); the “Already registered? Sign In” row was
  unchanged.
- **VERIFIED:** Corrected the registration response contract
  (`1f08dd4`): registration/status/resend expect HTTP 202 with
  endpoint-appropriate body statuses; verification and cancellation expect
  HTTP 200.
- **REPORTED:** Runtime observation: registration returned HTTP 202 and the
  status request returned HTTP 202. A successful resend returning HTTP 202 is
  confirmed by backend source, not runtime; the only resend response observed
  at runtime was HTTP 503 `delivery_failed`.
- **REPORTED:** A focused text-scale 2.0 test reported an existing password
  field overflow, also with the old button label. The current test suite does
  not cover text scale 2.0.
- **UNVERIFIED:** The complete real-backend flow with a delivered email, the
  appearance on a real phone, and Instructor registration.
- Validation: **VERIFIED** — `flutter analyze --no-pub` printed
  `No issues found! (ran in 38.2s)`; `flutter test --no-pub` printed
  `00:20 +116: All tests passed!`.

## 2026-11-17 — Password recovery matches the server

- The old School ID and reset-link screen no longer matched the server; it was
  replaced by the in-app email, code, and new-password flow. No backend,
  package, or Android changes were made.
- Validation: `flutter analyze` and `flutter test` passed.

## 2026-11-15 — Phase 5 password-recovery request

- Added the public forgot-password request screen, CSRF-protected API request,
  neutral response handling, and mocked API, validation, and route tests.
- Recovery links continue in the browser; no in-app reset, deep link, backend,
  package, or Android changes were made.
- Validation: `flutter analyze` passed; `flutter test` passed all 76 tests.

## 2026-11-16 — Debug Server settings and startup hardening

- Server settings stages 1–3 added persisted debug URL selection, connection
  testing, and debug-only any-host cleartext (`252b881`, `beb05e2`, `84993ab`).
- Documented/approved settings (`61cd16f`, `1dd72fe`, `b580613`); release APK
  inspection found `INTERNET` but no network security config; cleartext is blocked.
- Startup hardening in `cd6a941` bounds secure-storage waits and falls back
  safely. Set version `0.2.0+1` (`052719c`) and added `env/demo.example.json`
  (`a5701cd`).

## 2026-11-17 — Flutter CI

- Added pinned GitHub Actions workflow for Flutter analysis and tests on pushes
  to `main` and pull requests; no build or secrets.

## 2026-11-16 — GitHub mobile release

- Tag `v0.2.0` (title: `CTU-G Mobile v0.2.0-demo`); marked as a pre-release on 2026-11-16.
- DEBUG, `arm64-v8a` only: `app-arm64-v8a-debug.apk`; SHA-256
  `1289d9f08d99fb391bd55bbc89c0114c763486b5e37940f266ff1154a0d39da3`
  (matches the split-ABI build of `a5701cd`).
- Owner-tested on a real phone: starts, Server settings connects, and sign in works.
  Debug/demo only: plain HTTP, any typed address; trusted networks and test accounts only.

## 2026-11-15 — Debug cleartext and version 0.1.0

- Added debug cleartext for hotspot and current LAN demo addresses
  (`9896b3c`, `4794b0d`); set version `0.1.0+1` (`2cce8c2`).

## 2026-11-14 — Branding

- Moved and styled the web-like brand header/logo (`72942ae`) and added and
  refined the CTU-G launcher icon (`dad1a7d`, `080648b`).

## 2026-11-14 — Phase 4 authentication wrap-up

- Added the short mobile authentication reference and verified release APK
  permissions/network configuration; analysis and all 57 Flutter tests passed.
- Added an explicit pending-account generic-message widget test. Real-server
  Sign Up, pending-account, and rate-limit checks remain unverified.

## 2026-11-14 — Phase 4A reference snapshot and approval-scoping docs

- Copied the approved backend reference set verbatim into `docs/reference/backend/` and verified SHA-256 matches for each file.
- Added `docs/reference/backend/README.md` documenting the original repository, source commit, copy date, allowed usage, and the requirement to re-verify backend contracts before implementation.
- Added the Phase 4A feasibility, decision, backend requirements, and spike test-plan documents under `docs/testing/` and `docs/architecture/`.
- Added the mobile SRS addendum proposal to support explicit approval before any mobile auth implementation or isolated backend test is authorized.
- Documentation only; no backend change, dependency change, Android manifest change, or Flutter implementation was made.

## 2026-11-12 — Phase 3 inspection documentation

- Added backend API, authentication, role/permission, mobile API contract,
  backend proposal, proposed ADR-005, and Phase 3 evidence documentation.
- Recorded verified source facts separately from proposals and unresolved
  decisions. Documentation only; no application code, dependency, manifest
  or backend change; not pushed.
- Mobile authentication remains a proposal conditional on SRS approval and a
  separately approved, not-yet-designed isolated spike.

## 2026-11-12 — Phase 2 network audit

- Added emulator/device development network examples and a test that validates
  every tracked environment example through `AppConfig.fromValues`, including
  rejection of the production placeholder.
- Documented the live backend integration audit, development network
  architecture, runbook, and ADR-004. No backend, network-client, manifest,
  firewall, or authentication changes were made.
- Stage A: T1, T2, T3, and T5 passed. T6 through `adb reverse` is recorded as
  failed/inconclusive with cause undetermined and method-limited; the
  temporary reverse mapping was removed. T4/T7 were blocked because the active
  Wi-Fi profile was Public; T8 was not tested because no physical phone was
  available.
- The user reported accidentally starting an additional loopback Django
  `StatReloader` instance after T1; both processes were stopped before
  approved Stage A checks. That unapproved instance may have written ignored
  `__pycache__` files in the protected repository; their presence was not
  verified. The final protected-repository check did not inspect ignored files.
- The user also reports viewing Django admin pages in their own browser
  outside the test plan at about 14:49–14:50. Only GETs were observed and the
  user reports making no admin changes; possible session/audit-log side effects
  were not verified. These requests are not Phase 2 test evidence.
- Django `DEBUG=True` produced a detailed invalid-Host error page; this
  reinforces keeping the development server loopback-only.
- The built release manifest permission status remains unverified.

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
