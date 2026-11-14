# PHASE 4A — Authentication decision

## Decision summary

This project does not currently have approved mobile authentication scope. The backend code and documentation support a browser session + CSRF model, but they do not authorize Flutter deployment or browser JWT storage. The current implementation strategy therefore remains a proposal, not a live architecture decision.

## VERIFIED facts

### Backend contract

- `backend/apps/accounts/urls.py` exposes the browser-auth routes `/api/v1/auth/csrf/`, `/api/v1/auth/register/`, `/api/v1/auth/login/`, `/api/v1/auth/logout/`, and `/api/v1/auth/session/`.
- `backend/apps/accounts/views.py` enforces CSRF checks even for anonymous callers before registration and session actions.
- `backend/apps/accounts/session_auth.py` authenticates the user with Django `authenticate()` and then calls `login(request._request, account)` after verifying active status and active assigned role.
- `SessionView.get()` returns `{"authenticated": False}` when no valid, eligible session exists; otherwise it returns the current account and roles.
- The login serializer accepts only `school_id` and `password`.

### Current approval status

- The SRS says Flutter deployment is outside the release baseline and explicitly excludes browser JWT storage and Flutter deployment from the approved scope (`docs/SRS/CTU-G_Workspace_SRS_v1.md`, §1.2 and §2.2).
- ADR-005 states the mobile session+CSRF path is a proposal only and not an architectural commitment (`docs/decisions/ADR-005-MOBILE-AUTHENTICATION-STRATEGY.md`).

### Mobile state

- The mobile repo has no network client, no auth state container, no cookie persistence layer, and no sign-in/sign-up screens.
- Metadata indicates the project is currently awaiting the SRS approval step for mobile scope.

## Recommended direction

Option 1 — Reuse Django session + CSRF with a persistent cookie jar, `X-CSRFToken`, and validation on each unsafe call — is the only option that matches the current live backend contract and does not require a backend schema or token lifecycle change.

Future backend-change authority: owner/approver `[YOUR NAME]`; backend developer `[NAME]`; branch `[BRANCH NAME]`.

This recommendation is conditional on:

1. Written SRS/mobile addendum approval.
2. An approved isolated backend test environment.
3. A documented review of HTTPS, cookie persistence, and Android network security constraints.
4. No backend change without a separate proposal and explicit approval.

## UNVERIFIED / unresolved

- Whether the backend owner or project owner will approve the required mobile addendum.
- Whether an isolated test database and scripted identity will be permitted.
- Whether a separate branch and backend developer will be assigned for any future backend change.
- Whether course approver sign-off is available before Phase 4B implementation begins.

## Decision

Do not proceed with implementation or live spike activity until the mobile SRS addendum is approved and a separate, explicit authorization exists for the isolated environment and testing plan.
