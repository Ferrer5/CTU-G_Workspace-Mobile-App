# PHASE 4A — Backend requirements

## Current verified backend contract

This document records the server behavior that a future mobile client must respect if the mobile auth scope is later approved.

### Routes and methods

- `/api/v1/auth/csrf/` — `GET` only.
- `/api/v1/auth/register/` — `POST` only; public registration request; no session creation.
- `/api/v1/auth/login/` — `POST` only; accepts `school_id` and `password`; creates a Django session only for an eligible, approved, active account with a current active role.
- `/api/v1/auth/logout/` — `POST` only; invalidates the current session.
- `/api/v1/auth/session/` — `GET` only; returns current authenticated/unauthenticated state after rechecking backend eligibility.

### CSRF requirements

- The backend enforces CSRF checks for unsafe methods on registration, login, logout, and session work in the session/auth API layers.
- A valid CSRF cookie and matching token must be included for unsafe requests from the client.
- Current backend settings do not include a custom trusted-origin policy, so the request must match the expected local development host rules and secure-origin checks.

### Registration contract

- `requested_role` may only be `Student` or `Instructor`.
- The registration flow creates a new, pending, inactive account and no role assignment.
- Password validation is enforced server-side.
- Duplicate or invalid payloads receive validation errors and do not auto-activate the account.
- The backend returns a generic success message stating that eligible requests are pending administrative review.

### Login contract

- The accepted request fields are limited to `school_id` and `password`.
- Auth failure is intentionally generic and returns an `invalid_credentials` code for bad password, inactive account, unapproved account, or no active assigned role.
- Login success returns `{"authenticated": true, ...}` and current account role/permission metadata.

### Session contract

- Session validation rechecks account eligibility each request.
- If the account is rejected, inactive, or lacks an active assigned role, the API returns `{"authenticated": false}`.
- The client must never trust a locally stored boolean or cached user role.

## Requirements for any future mobile implementation

1. Use the existing server-side session model; do not assume a browser-only or local-only auth state.
2. Persist cookies securely and restore sessions only after server validation.
3. Always send a valid CSRF token for unsafe requests.
4. Treat non-JSON or malformed responses as possible failure states.
5. Never auto-login after sign-up.
6. Show only approved, non-sensitive account status on the client.
7. Recheck session status at app start and after sign-in/out transitions.

## UNVERIFIED / unresolved

- Any web/mobile deployment authorization.
- Whether the backend owner will approve a non-browser mobile session contract.
- Whether a production-ready secure-cookie configuration is required for a future deployment.

## Conclusion

The backend contract is workable for a session-based mobile auth design, but only after the mobile scope is explicitly approved and a safe isolated backend test environment is available.
