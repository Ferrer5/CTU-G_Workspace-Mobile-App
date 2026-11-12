# ADR-005 — Mobile Authentication Strategy

> **Phase 3 · Date:** 2026-11-12  
> **Status:** **PROPOSED — not an architectural commitment**  
> **Evidence basis:** Read-only backend, frontend and SRS inspection  
> **Proposed items are not implemented.**

## Context

The current backend routes browser session authentication with explicit CSRF.
The current SRS identifies Flutter deployment as outside the release baseline
unless later approved. No mobile auth client or configured SimpleJWT flow
exists.

## Existing implementation

`GET /api/v1/auth/csrf/`, `POST /api/v1/auth/login/`,
`POST /api/v1/auth/logout/`, and `GET /api/v1/auth/session/` are routed.
Unsafe requests require CSRF token/cookie validation and Origin checks when an
Origin header is present. Django requires a valid secure Referer for HTTPS
unsafe requests that omit Origin. Session lookup rechecks account status and
active role state.

## Options considered

1. Reuse existing session+CSRF from Flutter with a persistent cookie jar and
   `X-CSRFToken`.
2. Add mobile-only SimpleJWT access/refresh tokens alongside browser sessions.
3. Add a smaller session-compatible mobile endpoint/header variation.

## Advantages

- Option 1 reuses existing routes and preserves the current server-side session
  and per-request account/role checks without changing the backend for a
  development spike.
- Option 2 would define an explicit bearer-token contract and separate mobile
  from browser cookies.
- Option 3 could address a narrowly demonstrated incompatibility without
  replacing browser auth.

## Disadvantages

- Option 1 requires cookie persistence, CSRF header management, secure
  at-rest handling, and correct HTTPS Origin/Referer behavior.
- Option 2 adds endpoint, lifetime, refresh, rotation, logout/revocation,
  device-loss, role-change and operational policy that does not currently
  exist.
- Option 3 still changes backend behavior and is unnecessary until a specific
  blocker is demonstrated.

## Security implications

Keep the browser CSRF/session flow. Do not disable CSRF or weaken host/origin
controls. Secure storage alone does not make a token safe. Current settings do
not configure production Secure cookie behavior. Native cookie handling and
Android cleartext behavior are untested.

## Backend impact

No backend auth change is proposed for a developer-PC spike using existing
endpoints. This does not imply production readiness: any use beyond a
developer PC needs production-style settings (HTTPS, explicit hosts, Secure
cookies, and reviewed proxy configuration). Hosting is unresolved.

## Flutter impact

If approved, the spike would need a cookie-aware API layer, CSRF
bootstrap/header handling, cookie persistence, auth repository/state,
secure cookie persistence, and session-expiry/error handling. No package or
implementation choice is approved.

## Recommendation

**Primary proposal:** reuse session+CSRF with a persistent cookie jar and
`X-CSRFToken`, conditional on approval of the SRS mobile scope and a successful
isolated spike. This is a proposal, **not an architectural commitment**.

The spike is **NOT DESIGNED / NOT APPROVED**. The test runner creates disposable
MySQL databases, but a live server connected to a separate test database and
a scripted test identity have not been designed. Creating test accounts is a
write and needs separate approval.

Proposed spike pass criteria: cookie persistence and rotation work; unsafe
requests pass only with valid CSRF and accepted origin behavior; logout clears
the client session; role/status revocation denies the next session check.
Test only with an approved isolated environment and scripted test identity,
never a real account. If it fails for a verified technical/security reason,
stop and revisit a distinct token contract.

## Alternatives rejected

- Immediate SimpleJWT adoption: package presence is not configuration; no
  token endpoints, lifetimes, or blacklist app are present. Its lifecycle
  would add complexity before need is established.
- Browser-session reuse without cookie persistence or CSRF handling: does not
  satisfy the existing request contract.
- Removing CSRF or broadly allowing hosts/origins: protection reduction.

## Unresolved

- SRS addendum / authorization of Flutter deployment.
- Spike environment, including MySQL isolation and test-account creation.
- Cookie-jar persistence and HTTPS client behavior.
- Production hosting/domain and production settings.
- Whether a development path uses loopback reverse forwarding, `10.0.2.2`,
  or LAN.
- Backend change owner and branch.
- Android release INTERNET permission and package choices.

## Evidence

Source references: `backend/config/urls.py:urlpatterns`,
`backend/apps/accounts/session_auth.py:WorkspaceSessionAPI`,
`_workspace_account`, `LoginView`, `LogoutView`, `SessionView`,
`backend/apps/accounts/views.py:CSRFView`,
`backend/config/settings.py:DEBUG`, `ALLOWED_HOSTS`, and the session/reset
settings. Scope reference: SRS §1.2 and §2.2.

See the [Authentication Architecture](../architecture/AUTHENTICATION_ARCHITECTURE.md)
and [Phase 3 Inspection Report](../testing/PHASE-3-INSPECTION-REPORT.md).
