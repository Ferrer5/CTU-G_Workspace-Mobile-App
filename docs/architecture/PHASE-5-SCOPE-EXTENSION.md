# PHASE 5 — Scope extension: connectivity, release readiness, password recovery request

**Status:** PROPOSED / NOT APPROVED
To: Project owner Janrey Ferrer; course instructor/reviewer Glicerio Baguia (approval: pending)

## Why
Phase 4 delivered Sign In, Sign Up, session restore and logout. The backend has no live dashboard
modules yet, and no live route to approve registrations, so a dashboard shell is deferred to a later phase.

## In scope
A. Password recovery REQUEST screen: School ID + registered email -> POST /api/v1/auth/forgot-password/
   (verify the contract in backend source first). Show the neutral message; handle 503
   recovery_disabled with "not available yet", 429 and network errors. The reset itself is completed in the
   browser from the emailed link; no in-app token entry and no deep links in this phase.
B. Connectivity PROPOSAL (document only): what a real phone needs (ALLOWED_HOSTS, server bind
   address, firewall, HTTPS or a stable hosted address, per-environment API_BASE_URL), written as a
   backend change proposal in docs/BACKEND_CHANGE_REGISTER.md. Nothing is applied to the backend.
C. Release readiness: a signed release APK with the keystore kept OUTSIDE the repo and never
   committed, a version number, a GitHub Actions workflow that runs flutter analyze and flutter
   test, and Android backup rules so stored cookies are not restored to another device (any
   manifest change is proposed first and needs separate approval).
D. Close Phase 4 evidence gaps: real Sign Up, pending-account sign-in and rate-limit checks in the
   backend sandbox, run by the owner.

## Out of scope
Dashboard shell and module screens; deep links; SMTP/email changes; any backend change; browser JWT
storage; weakening CSRF/Host/Origin checks.

## Acceptance criteria
1. Forgot-password request screen works against the real API and shows only the neutral message.
2. A connectivity proposal exists, and no backend file was changed.
3. A release APK builds with the keystore outside the repo; CI runs analyze and tests.
4. Phase 4 manual checks D are recorded by the owner.

## Signatures
- Project owner: ______________________  Date: __________
- Course instructor / reviewer: ______________________  Date: __________
