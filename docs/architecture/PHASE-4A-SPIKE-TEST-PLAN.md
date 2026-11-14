# PHASE 4A — Spike test plan

## Scope

This document describes a future isolated mobile-auth spike design only. It does not create or run any test environment, account, database, or server. That activity remains blocked pending separate approval.

## VERIFIED constraints from Turn 1

- The live backend is currently a local Django development setup with `DEBUG = True` and `ALLOWED_HOSTS = []`.
- The backend auth flow is session-based and CSRF protected.
- The app repository does not yet include mobile auth code, and no dependency changes are approved.
- The SRS does not currently authorize Flutter deployment or browser JWT storage.

## Proposed isolated design

### Environment

- Use the backend's built-in isolated sandbox flow, not a disposable copy of the repository.
- Keep the original protected backend untouched and verify it remains clean using the file baseline checks before and after any sandbox setup.
- Use the dedicated sandbox database `ctug_review_sandbox`; do not use the live `ctug_workspace` database.
- Run the sandbox behind `127.0.0.1` or `localhost` only and keep the middleware in `config.review_sandbox_middleware.LoopbackOnlyMiddleware` active.
- The backend sandbox settings module is `config.review_sandbox_settings`, which sets `ROOT_URLCONF = "config.review_sandbox_urls"`, `ALLOWED_HOSTS = ["127.0.0.1", "localhost"]`, and isolates the cookie names to `ctug_review_sandbox_session` and `ctug_review_sandbox_csrf`.
- The Android emulator path should use `adb reverse tcp:8001 tcp:8001` so the app reaches the host loopback as `127.0.0.1`, without an `ALLOWED_HOSTS` change.
- The sandbox requires `CTUG_REVIEW_SANDBOX_ACK=SANDBOX_ONLY` and checks `DATABASES["default"]["ENGINE"] == "django.db.backends.mysql"`, the DB host is `localhost`/`127.0.0.1`/`::1`, and the DB name is `ctug_review_sandbox`.
- Run only loopback-local traffic; do not expose the feature on a public network.

### Sandbox seed and account model

- `seed_review_sandbox` is the intended built-in sandbox seeding command and contains a verification guard that requires `settings.SETTINGS_MODULE == "config.review_sandbox_settings"` and an empty sandbox schema before any writes.
- The sandbox preview (`--apply` omitted) performs a read-only preview and refuses writes if the target is not the isolated sandbox.
- The actual apply flow (`python manage.py seed_review_sandbox --apply --confirm CTUG-REVIEW-SANDBOX-SEED-ONLY`) creates a synthetic admin plus a synthetic pending instructor and pending student and one approved active student. It also creates the admin grant bindings and audit receipts.
- The expected seeded IDs are:
  - `SANDBOX-ADMIN-001`
  - `SANDBOX-STUDENT-PENDING-001`
  - `SANDBOX-INSTRUCTOR-PENDING-001`
  - `SANDBOX-STUDENT-ACTIVE-001`
- The sandbox is documented as a local demo-only environment for registration review and must never be used with real data.

### Required cases to be designed later

- CSRF bootstrap
- login and invalid credentials
- cookie persistence and session restoration
- session rotation on login
- logout
- pending account rejection
- deactivated account handling
- expired or invalid session handling
- role revocation handling
- missing CSRF token
- malformed responses and 503 responses
- server unavailable / network failure

### Cleanup procedure

1. Stop the disposable Django server.
2. Remove the disposable backend copy.
3. Drop the disposable test database.
4. Confirm no DB or server artifacts remain.
5. Verify the protected repo still matches its earlier baseline and hash evidence.

## UNVERIFIED

- Whether `adb reverse tcp:8001 tcp:8001` works reliably for the emulator on this workstation and whether the host is accepted as `127.0.0.1` under the sandbox `ALLOWED_HOSTS` values.
- Whether Android cleartext HTTP behavior will block the test path on the target emulator or device without a network-security config change.
- Whether the backend sandbox can be started with the required environment variables and local MySQL configuration without affecting the protected repository or the live database.
- Whether the course approver will permit sandbox seeding and review-flow testing on the local machine.

## Requires separate approval before execution

- SRS/mobile authorization approval.
- Backend-owner decision on any disposable backend copy or configuration.
- Explicit authorization to create a throwaway database and fake test identity.
- Confirmation that the copy lives outside both repositories and is cleaned up after testing.

## Decision

This plan is documentation-only and must remain blocked until separate approval is granted.
