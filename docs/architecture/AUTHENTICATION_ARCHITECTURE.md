# CTU-G Workspace Authentication Architecture

> **Phase 3 · Date:** 2026-11-12  
> **Status:** Verified inspection; strategy PROPOSED, not an architectural commitment  
> **Evidence basis:** Read-only backend/frontend source inspection and existing reports  
> **Proposed items are not implemented.**

## Evidence and scope

This is a read-only record of the backend's current browser auth and a
conditional mobile proposal. No auth code, backend setting, package, Android
manifest, server, or database was changed or exercised for this document.

## Existing session + CSRF implementation

**Source inspection:** `backend/apps/accounts/session_auth.py:WorkspaceSessionAPI`
explicitly uses no DRF authentication classes and `AllowAny`, then manually
reads Django's session or applies `CSRFCheck` to every unsafe method.
`LoginView` authenticates School ID/password, requires an active approved
account and active assigned role, and creates a Django session. `LogoutView`
calls Django `logout()`. `SessionView` rechecks eligibility and returns
current account/role/permission hints.

`CSRFView.get()` returns `{"csrfToken": ...}` using Django `get_token()`;
CSRF middleware also sets/updates the CSRF cookie on the response. A native
client would need to retain the `csrftoken` and `sessionid` cookies and submit
the current CSRF token in `X-CSRFToken`. Login rotates session and CSRF state
(`test_login_rotates_anonymous_session_key_and_csrf_token`, source only).

### Django defaults, not configured by the project

No `SESSION_*`, `CSRF_*`, `SECURE_*`, or `CORS_*` settings were found in
`backend/config/settings.py`. Django 6.1 defaults therefore apply:

| Setting | Default |
|---|---|
| `SESSION_COOKIE_HTTPONLY` | `True` |
| `SESSION_COOKIE_SAMESITE` | `Lax` |
| `SESSION_COOKIE_SECURE` | `False` |
| `SESSION_COOKIE_AGE` | `1209600` seconds (two weeks) |
| `SESSION_SAVE_EVERY_REQUEST` | `False` (not sliding on each request) |
| `CSRF_COOKIE_HTTPONLY` | `False` |
| `CSRF_COOKIE_SAMESITE` | `Lax` |

These are framework defaults, not project-hardened production settings.

### CSRF Origin and Referer behavior

**Source inspection:** installed Django `CsrfViewMiddleware.process_view()`
implements the following for unsafe requests:

- HTTP: if an Origin header exists, it must match the request origin or a
  trusted origin. No Referer is required when plain HTTP has no Origin.
- HTTPS: if Origin is absent, a valid secure Referer matching the request host
  or a trusted host is required. If a native client sends neither, Django
  rejects the request.
- In either case, after origin checks Django requires a CSRF cookie and a
  matching submitted token. `WorkspaceSessionAPI.initial()` invokes this
  check even for anonymous login callers.

`CSRF_TRUSTED_ORIGINS` is not configured in the project settings. Same-host
Origin/Referer matching does not depend on it; a different origin would need
approved trust configuration. Runtime behavior from Flutter is **NOT TESTED**.

The web frontend uses a Vite `/api` proxy that preserves Host and Origin
(`frontend/vite.config.ts`); this explains the browser development topology.
Native HTTP clients do not use browser CORS enforcement.

## Current revocation and expiry behavior

`_workspace_account()` in `session_auth.py` rechecks account active state,
approved status, staff/superuser exclusion, and active assigned role on every
session lookup. A deactivated, unapproved, or de-roled user is denied on the
next check. The code does not establish that the stored Django session row is
deleted when role or status changes. Logout clears the caller's session.

FR-AUTH-04 is **PARTIALLY IMPLEMENTED**: logout and immediate denial are
present, but explicit session invalidation on role/status change and an
approved expiry policy with tests are unresolved. Existing test source includes
`test_session_reflects_removed_role_without_cached_grants`,
`test_session_reflects_revoked_approval`, and
`test_logout_requires_csrf_and_clears_session`; tests were not run here.

## Login, registration and recovery lifecycle

- Login returns the same generic 401 for bad credentials, Pending/Rejected/
  inactive accounts, framework staff/superusers, and accounts without an
  active assigned role. A native client cannot distinguish pending approval
  from a wrong password. This aligns with the anti-enumeration intent in
  SRS FR-REG-03.
- Public registration accepts Student/Instructor only. It creates a Pending,
  inactive account plus profile, hashes the password, and assigns no role.
  A valid duplicate School ID gets the same public acknowledgement. The
  form/serializer do not collect academic placement fields.
- Review routes are not included in the live URLconf; code requires both
  review and approval gates. A console bootstrap command is for first Admin
  provisioning, not a public applicant-approval path.
- Password recovery is **implemented in code, disabled by default, and not
  established as mobile-usable**. Its link targets the web frontend URL
  configured by `WORKSPACE_PUBLIC_BASE_URL` (default
  `http://localhost:5173`) with token details in a URL fragment.
  `PASSWORD_RESET_TIMEOUT=1800` seconds. Django's default token binds to user
  identity/state including password and last-login, and password change
  invalidates it. Throttles are `4/min` and `20/day`; neutral responses reduce
  enumeration. SMTP is separately disabled by default.

## Rate limiting

**Source inspection:** rate limit cache keys use `REMOTE_ADDR`, not untrusted
forwarded headers. The project does not define `CACHES`, so Django's local
memory cache is used by default; counters are not shared across worker
processes.

| Endpoint | Throttle | Limit |
|---|---|---|
| Login | `LoginBurstThrottle` / `LoginHourlyThrottle` | 8/min / 40/hour |
| Registration | `RegistrationBurstThrottle` / `RegistrationDailyThrottle` | 5/min / 30/day |
| Forgot/reset password | `ResetThrottle` / `ResetDailyThrottle` | 4/min / 20/day |

## SimpleJWT status

**Source inspection:** `djangorestframework_simplejwt` appears in requirements,
but it is not in `INSTALLED_APPS`; no `SIMPLE_JWT` settings, JWT auth class,
token views, refresh route, or blacklist app usage was found. SimpleJWT is
**NOT EXISTING as a configured or used auth flow**.

## Comparison: existing versus proposed

| Criteria | Session authentication | SimpleJWT |
|---|---|---|
| Existing implementation | **EXISTING:** server-side Django session, explicit CSRF and auth endpoints | **NOT EXISTING:** package installed, not configured, not used |
| Native Flutter suitability | **PROPOSED reuse:** possible with persistent cookie jar and CSRF header; runtime untested | Potential, but no configured token contract |
| CSRF requirements | Existing unsafe routes require token/cookie and origin rules | A new bearer flow needs its own threat model; browser CSRF remains |
| Token/cookie handling | Persist session and CSRF cookies; process login rotation | Needs issuance, storage, refresh/rotation and validation |
| Logout and revocation | Logout invalidates session; eligibility rechecked on session lookup | No blacklist app/config; revocation design absent |
| Expiration | Django default two weeks, not sliding per request | No token lifetime configured |
| Security risks | Cookie persistence, HTTPS Origin/Referer, default non-Secure cookie configuration | Stolen tokens, device loss, stale access tokens and refresh revocation complexity |
| Required backend work | None proposed for a development spike; production configuration is separately unresolved | New API/lifecycle work |
| Required Flutter work | Cookie jar, CSRF header, secure persistence, auth state and expiry handling | Secure token store, interceptors, refresh and revocation handling |
| Recommendation | **Primary proposal:** reuse conditionally after SRS approval and isolated spike | Strongest alternative only if spike/policy establishes a need |

## Proposal and unresolved items

**PROPOSED, not an architectural commitment:** reuse existing session + CSRF
for an isolated mobile spike, with persistent cookies and `X-CSRFToken`, if
mobile scope receives SRS approval. The spike is **NOT DESIGNED / NOT
APPROVED**. The project test runner creates disposable MySQL test databases;
using an isolated database behind a live server and creating a scripted
identity has not been designed. Creating test accounts is a write operation
requiring separate approval.

No backend auth change is proposed for a development spike only. Any use beyond
a developer PC requires production-style configuration (HTTPS, explicit hosts,
secure cookies, and deployment settings); hosting and configuration are
UNRESOLVED.

## Related documents

- [API Architecture](API_ARCHITECTURE.md)
- [Mobile API Specification](MOBILE_API_SPECIFICATION.md)
- [Proposed ADR-005](../decisions/ADR-005-MOBILE-AUTHENTICATION-STRATEGY.md)
- [Phase 3 Inspection Report](../testing/PHASE-3-INSPECTION-REPORT.md)
- [Phase 2 Network Architecture](NETWORK_ARCHITECTURE.md)
