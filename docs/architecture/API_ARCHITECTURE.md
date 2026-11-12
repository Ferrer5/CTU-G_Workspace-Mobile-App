# CTU-G Workspace API Architecture

> **Phase 3 · Date:** 2026-11-12  
> **Status:** Verified inspection; proposals remain pending  
> **Evidence basis:** Read-only inspection of the live backend and web client; existing Phase 2 reports  
> **Proposed items are not implemented.**

## Scope and evidence

This document records the routed API surface observed in the protected backend
during Phase 3 inspection. It does not claim that a route was dynamically
tested. No backend code, database, or server was changed or accessed for this
documentation stage.

Evidence labels:

- **Source inspection** — checked in current source.
- **Existing test evidence** — stated in an existing test report or test source; not rerun here.
- **Not executed** — no runtime request or test was made in this stage.
- **Proposed / Unresolved** — not implemented or approved.

## Routing and middleware

`backend/config/urls.py:urlpatterns` includes the accounts URLconf at
`/api/v1/auth/` and Django Admin at `/admin/`. No academic, finance, clearance,
announcement, notification, report, support, or group-rating URLconf is
included. The seven account endpoints are listed below.

`backend/config/settings.py:MIDDLEWARE` includes CORS, security, sessions,
common, CSRF, authentication, messages, and clickjacking middleware. The
React/Vite development client proxies `/api` to Django and preserves Host and
Origin (`frontend/vite.config.ts`); this is not a native-client CORS contract.

### Routed endpoints

| Endpoint | Method(s) | View | Access mechanism | Current mobile note |
|---|---|---|---|---|
| `/api/v1/auth/csrf/` | GET, HEAD, OPTIONS | `CSRFView` | `AllowAny`; CSRF bootstrap | Existing browser-oriented token bootstrap |
| `/api/v1/auth/register/` | POST, OPTIONS | `RegistrationView` | `AllowAny` plus explicit `CSRFCheck` | Public registration request; no login/session issued |
| `/api/v1/auth/login/` | POST, OPTIONS | `LoginView` | `AllowAny` plus explicit `CSRFCheck` | Session-cookie flow; native use untested |
| `/api/v1/auth/logout/` | POST, OPTIONS | `LogoutView` | `AllowAny` plus explicit `CSRFCheck` | Clears caller's session |
| `/api/v1/auth/session/` | GET, HEAD, OPTIONS | `SessionView` | Direct Django session read; no CSRF on safe method | Returns current session state |
| `/api/v1/auth/forgot-password/` | POST, OPTIONS | `PasswordResetRequestView` | `AllowAny`, feature gate, CSRF | Feature disabled by default; link opens web frontend |
| `/api/v1/auth/reset-password/` | POST, OPTIONS | `PasswordResetConfirmView` | `AllowAny`, feature gate, CSRF and reset token | Feature disabled by default |

Routes and methods come from `backend/config/urls.py:urlpatterns` and
`backend/apps/accounts/urls.py: urlpatterns`.

### Code present but not routed

- `registration_review_urls.py` and `registration_bulk_urls.py` are not included
  by the root URLconf.
- Review API code requires both
  `WORKSPACE_REGISTRATION_REVIEW_API_ENABLED` and
  `WORKSPACE_REGISTRATION_APPROVAL_ENABLED`; current main settings do not
  define either as enabled.
- Review service code also checks the approval feature flag and has no live
  route by default.
- These are not available mobile APIs.

### Modules with no API

No active API routes were found for `academic`, `finance`, `clearance`,
`announcements`, `notifications`, `reports`, `support`, or `group_rating`.
The inspected academic, finance, clearance, announcement, and group-rating
model/view files are placeholders. The app names in `INSTALLED_APPS` and
catalogue do not imply operational endpoints.

## Error handling and response consistency

| Case | Current behavior |
|---|---|
| In-view API exceptions for registration/CSRF | `PublicJSONView.handle_exception()` maps DRF errors to `{ "error": { "code", "message", "fields"? } }`; unexpected registration errors become a generic 503 envelope. |
| In-view API exceptions for session/login/logout/reset | `WorkspaceSessionAPI.handle_exception()` maps DRF errors to `{ "error": { "code", "message" } }`; unexpected exceptions become a generic 503 envelope. |
| Login denial | Explicit 401 `invalid_credentials`; pending/rejected/inactive/no-role and bad-password cases are intentionally indistinguishable. |
| Password recovery request | Neutral 202 acknowledgement hides whether an eligible account matched; lookup/mail exceptions are logged by exception type and do not disclose the target. |
| Unknown route with `DEBUG=True` | Django debug 404 is a technical HTML response, not the API JSON envelope. |
| Errors outside a view-level handler | May be Django HTML in this debug configuration; client must tolerate non-JSON responses. |
| Pagination / date serialization | No pagination in the seven routed auth endpoints. Pagination and ISO timestamps occur in inactive review API code only. |

**Source inspection:** these handlers do not establish one universal success
schema. Clients must distinguish endpoint-specific success bodies and treat
non-JSON failures as possible.

## What mobile can call today

**Verified by source inspection:** only the seven routed auth endpoints above
are in the API URLconf. Their intended contract is detailed in
[Mobile API Specification](MOBILE_API_SPECIFICATION.md).

**Not executed:** no mobile HTTP request or auth spike was run. Registration
and password recovery are separate product decisions; recovery is off by
default. No service screen can retrieve academic, finance, clearance,
announcement, notification, report, support, or group-rating data today.
Each future service API needs its own design, object-scope controls, tests, and
approval.

## Known limitations

- `DEBUG=True` and `ALLOWED_HOSTS=[]` are development settings; non-loopback
  development and production require separate, approved configuration.
- Android release manifest lacks `INTERNET`; no Android manifest changes are
  approved in this phase.
- The project has no mobile API client implementation.
- No dynamic API checks were performed in the documentation stage.

## Related documents

- [Authentication Architecture](AUTHENTICATION_ARCHITECTURE.md)
- [Role and Permission Mapping](ROLE_PERMISSION_MAPPING.md)
- [Mobile API Specification](MOBILE_API_SPECIFICATION.md)
- [Phase 3 Inspection Report](../testing/PHASE-3-INSPECTION-REPORT.md)
- [Backend Integration Baseline](BACKEND_INTEGRATION_BASELINE.md)
- [Phase 2 Network Architecture](NETWORK_ARCHITECTURE.md)
