# Mobile authentication

## Architecture and API

The Flutter app uses Dio in `lib/features/auth/data/`, a repository/controller in
`lib/features/auth/`, and Riverpod auth state to drive GoRouter in
`lib/app/router.dart`. Startup validates the server session; the minimal landing
screen displays the server-returned School ID and roles and offers logout.

The client uses these five `/api/v1/` endpoints:

| Method | Path | Purpose |
|---|---|---|
| GET | `auth/csrf/` | Bootstrap CSRF cookie/token |
| POST | `auth/login/` | Sign in with only `school_id` and `password` |
| POST | `auth/register/` | Submit the nine registration fields; HTTP 202 is required |
| GET | `auth/session/` | Restore and validate the server session |
| POST | `auth/logout/` | End the server session |

## Session and security

`PersistCookieJar` stores session and CSRF cookies through
`flutter_secure_storage`; its storage prefix is scoped by API host and port.
Before every POST, the client reads the current CSRF cookie from the jar and
sends `X-CSRFToken`, so the rotated cookie after login is used. Cookies are
cleared only after the server confirms logout. Startup trusts only the
`/session/` response; roles are display-only and are never authorization
decisions. Credentials, cookies, and tokens are not logged or stored as plain
preferences; the client does not use JWTs.

The release APK was built and inspected: it contains `INTERNET`, has no
`networkSecurityConfig` manifest reference, and does not package the debug
loopback network-security XML. Release therefore retains Android's default
cleartext blocking; the debug-only exception is limited to loopback.

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

Actual checks on 2026-11-14:

| Command | Result |
|---|---|
| `flutter analyze` | Passed; no issues found |
| `flutter test` | Passed; all 57 tests |
| `flutter build apk --release --dart-define-from-file=env\sandbox.example.json` | Passed; `build\app\outputs\flutter-apk\app-release.apk` |

Owner-confirmed emulator checks against the real local server: sign in, landing
screen, restore after restart, logout, sign in again, wrong password, and
server-down retry. Real-server Sign Up, pending-account login, and rate limiting
were not manually tested. The tests are mocked; no backend command or request
was run for this wrap-up.

## Limitations

- Physical phones over LAN/Wi-Fi are unsupported: loopback only. A different
  address requires an approved backend `ALLOWED_HOSTS` change and app rebuild.
- No password recovery. Duplicate School IDs use the same neutral confirmation:
  “If eligible, your request is pending review.”
- Logout requires the server to confirm; an offline logout is not reported as
  successful.
- Release builds block plain HTTP; use HTTPS outside the approved debug
  loopback path.
- Accounts and persisted cookies are isolated per API server.
