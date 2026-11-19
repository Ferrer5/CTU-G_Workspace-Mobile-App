# Local Testing Report

Report date: 2026-11-20

This report complements the [authentication reference](../architecture/AUTHENTICATION.md),
[sign-up verification report](SIGNUP-VERIFICATION-REPORT.md), and
[development environment guide](../setup/DEVELOPMENT_ENVIRONMENT.md).

## Build and configuration

- **REPORTED:** A local APK built with
  `flutter build apk --release --build-name 0.2.1 --build-number 2` and without
  `--dart-define-from-file` showed the startup fallback on a phone; this APK
  was not released.
- **VERIFIED:** `AppConfig.fromEnvironment()` requires compiled `APP_ENV` and
  `API_BASE_URL`; missing values prevent startup. The v0.2.0 demo asset was a
  DEBUG APK. Production config requires an HTTPS API URL, while release builds
  hide debug-only Server settings and Android blocks plain HTTP.
- **REPORTED:** v0.2.2 has not yet been built. The intended demo command is
  `flutter build apk --debug --split-per-abi --dart-define-from-file=env\demo.example.json`.

## Password recovery

- **REPORTED:** On the local backend, the app reached the code step and received
  the neutral HTTP 202 response, but no code arrived for an older test account.
- **VERIFIED:** A code is issued only for an active, approved, non-staff,
  non-superuser account with an active role and current email-verification
  proof. The read-only Account admin omits the proof fields. Ineligible accounts
  receive the same neutral response; failed background delivery produces a
  warning without logging the recipient, while a successful send has no
  per-message log.
- **REPORTED:** For local testing only, the owner set verification proof for a
  test account through the Django shell on a local database. Do not use this
  approach on shared servers; this report does not include shell commands.
- **UNVERIFIED:** A delivered code and a completed password change.

## Connection findings

- **REPORTED:** These observations came from replaying requests against a copy
  of the backend in a sandbox, not from the project machine: HTTPS mode
  redirected plain-HTTP requests; a host absent from the allowed-host setting
  returned HTML 400; and an HTTPS tunnel in front of plain-HTTP Django failed
  CSRF with 403 unless trusted origins or HTTPS mode with proxy trust was
  configured.
- **VERIFIED:** Backend source configures allowed hosts, HTTPS redirects,
  trusted CSRF origins, and optional proxy SSL trust. The mobile connection
  test checks the CSRF token in the response body but does not check whether the
  CSRF cookie was retained. Sign In and Sign Up use generic text for missing
  CSRF cookies or transport failures.
- **VERIFIED:** Checking CSRF-cookie retention and showing clearer diagnostic
  messages are OPEN items and are not implemented.
- **UNVERIFIED:** A real HTTPS test using a real certificate.

## Retry behavior and open work

- **VERIFIED:** The mobile API client has no automatic request retry. It reads
  server retry intervals for cooldown handling.
- **REPORTED:** Exponential backoff for read-only GET requests was discussed and
  not adopted.
- **UNVERIFIED:** Complete real-backend sign-up and recovery flows with delivered
  codes, and the new auth layout on a real phone.
- **REPORTED:** The v0.2.2 demo release remains open: version bump, release docs,
  demo build, SHA-256, and GitHub pre-release are still pending.
