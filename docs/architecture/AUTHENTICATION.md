# Mobile authentication

## Architecture and API

The Flutter app uses Dio in `lib/features/auth/data/`, a repository/controller in
`lib/features/auth/`, and Riverpod auth state to drive GoRouter in
`lib/app/router.dart`. Startup validates the server session; the minimal landing
screen displays the server-returned School ID and roles and offers logout.

The client uses these twelve `/api/v1/` endpoints:

| Method | Path | Request | Success |
|---|---|---|---|
| GET | `auth/csrf/` | No body | 200 |
| POST | `auth/login/` | `{school_id, password}` | 200 |
| POST | `auth/register/` | `{school_id, email, first_name, middle_name, last_name, suffix, requested_role, password, password_confirmation}` | 202 (`verification_required` or `existing_verification`) |
| GET | `auth/register/verification/` (optional `?requested_role=Instructor`) | No body; staging cookie | 202 (`verification_required` or `existing_verification`) |
| POST | `auth/register/verify/` (optional `?requested_role=Instructor`) | `{code}`; staging cookie | 200 (`completed`) |
| POST | `auth/register/resend/` (optional `?requested_role=Instructor`) | `{}`; staging cookie | 202 (`verification_required`) |
| POST | `auth/register/cancel/` (optional `?requested_role=Instructor`) | `{}`; staging cookie | 200 (`cancelled`) |
| POST | `auth/forgot-password/` | `{email}` | 202 (neutral response) |
| POST | `auth/forgot-password/verify/` | `{email, code}` | 200 (`verified`); sets a single-use HttpOnly ticket cookie |
| POST | `auth/reset-password/` | `{email, password, password_confirmation}`; ticket cookie | 200 |
| GET | `auth/session/` | No body | 200 (`authenticated` true or false) |
| POST | `auth/logout/` | `{}` | 200 (`authenticated` false) |

Staged sign-up continues through an HttpOnly cookie scoped to
`/api/v1/auth/`; it is SameSite Strict and Secure when backend HTTPS is enabled.
The cookie is deleted after successful verification or cancellation, and
verification does not create a login session. Completion creates an inactive
account with `Pending` status for administrative review.

## Session and security

`PersistCookieJar` stores session and CSRF cookies through
`flutter_secure_storage`; its storage prefix is scoped by API host and port.
Before every POST, the client reads the current CSRF cookie from the jar and
sends `X-CSRFToken` and an `Origin` matching the API base URL, so the rotated
cookie after login is used. The hosted HTTPS Origin/Referer behavior remains
to be verified in an isolated test. Cookies are cleared only after the server
confirms logout. Startup trusts only the
`/session/` response; roles are display-only and are never authorization
decisions. Credentials, cookies, and tokens are not logged or stored as plain
preferences; the client does not use JWTs.

Password recovery runs fully in the app: email, 6-digit emailed code, then new
password. Verification stores a single-use HttpOnly ticket cookie for the final step.
The first step always shows neutral copy, and backend wording is never shown.

Recovery codes are issued only for active, approved, non-staff, non-superuser
accounts with an active role and matching email-verification proof; legacy
accounts without that proof are ineligible, and the read-only Account admin
does not expose the proof fields. A missing code can have several silent causes,
including ineligibility or delivery failure; the app cannot distinguish them
because the response is neutral by design. **REPORTED:** The owner set proof for
a test account through the Django shell on a local database for local testing
only; do not use this approach on shared servers.

## Startup resilience

Startup waits at most 3 seconds for saved server settings, then uses the
compiled API URL; cookie reads and session restore are bounded to 15 seconds.
Unhandled startup errors show a safe fallback screen; logs are generic and
secret-free. `flutter_secure_storage` 11.2.0 defaults Android `resetOnError`
to true, so decryption errors can erase stored session cookies; keep the default.

## Debug server settings
In debug/demo builds, use Server settings on Sign In or the startup retry screen to choose a host/port and test `auth/csrf/`.
The backend must include the host in `ALLOWED_HOSTS`, listen on the network interface, and allow traffic through the firewall.
Debug builds permit cleartext to any host only for this feature; HTTP is unencrypted. Release builds keep the compiled HTTPS URL.

The release APK was rebuilt and inspected: it contains `INTERNET`, has no
`networkSecurityConfig` manifest reference, and does not package
`network_security_config.xml`. The server-settings route is gated by
`kDebugMode`; its disabled-route test passes. Release retains Android's default
cleartext blocking and the compiled HTTPS API URL.

## Running and verification

Start the appropriate local backend yourself, then run in PowerShell:

```powershell
# Real local server
adb reverse tcp:8000 tcp:8000
flutter run --dart-define-from-file=env\local-real.json

# Approved sandbox (see [the sandbox runbook](PHASE-4A-SPIKE-RUNBOOK.md))
adb reverse tcp:8001 tcp:8001
flutter run --dart-define-from-file=env\sandbox.example.json
```

Run `flutter test` for the current test suite. Recorded checks:

| Command | Result |
|---|---|
| `flutter analyze` | Passed; no issues found |
| `flutter test` (Phase 4 wrap-up, 2026-11-14) | Passed |
| `flutter build apk --release --dart-define-from-file=env\sandbox.example.json` | Passed; `build\app\outputs\flutter-apk\app-release.apk` |

Owner-confirmed emulator checks against the real local server: sign in, landing
screen, restore after restart, logout, sign in again, wrong password, and
server-down retry. Real-server Sign Up, pending-account login, and rate limiting
were not manually tested. The tests for that wrap-up were mocked; no backend
command or request was run then.

Phase 5 validation on 2026-11-15: `flutter analyze` and `flutter test` passed.
Recovery API behavior was mocked; no real backend request was made.

Current validation (2026-11-17): `flutter analyze` passed; `flutter test`
passed all 97 tests.

## Limitations

- Server settings can select a different server at runtime in debug/demo builds;
  the backend must allow its host, listen on an accessible interface, and permit
  traffic through the firewall.
- Recovery requires the server's ticket cookie from code verification.
- Logout requires the server to confirm; an offline logout is not reported as
  successful.
- Release builds block plain HTTP; debug builds allow cleartext to any host for
  the Server settings feature only.
- Accounts and persisted cookies are isolated per API server.
