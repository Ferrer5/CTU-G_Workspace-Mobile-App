# Phase 3 Backend Change Proposal

> **Phase 3 · Date:** 2026-11-12  
> **Status:** PROPOSALS ONLY; all approval states PENDING  
> **Evidence basis:** Read-only inspection of current backend and mobile repository  
> **Proposed items are not implemented.**

## Boundary

No backend change was made during Phase 3. This document records conditional
proposals only; the user explicitly did not approve implementation. The
backend remains on branch `ronald`, and ownership/branch for any later backend
work is unresolved. The existing user-owned
`backend/config/settings.py` two-line first-admin bootstrap flag was not
modified.

## Pending change register

| Classification | File | Current behavior (verified) | Problem / evidence | Proposed change (not implemented) | Technical necessity | Alternative | Risks | Required tests | Approval |
|---|---|---|---|---|---|---|---|---|---|
| OPTIONAL, conditional on path | `backend/config/settings.py` | `DEBUG=True`, `ALLOWED_HOSTS=[]`; Django dev fallback accepts localhost/loopback but rejects `10.0.2.2` and LAN Hosts | Phase 2 T5 reached Django at `10.0.2.2` and received 400 DisallowedHost; T6 `adb reverse` inconclusive | If direct emulator alias is selected, add only `10.0.2.2` to an approved host configuration; if LAN is selected, allow only the approved LAN host | Needed only for a chosen non-loopback Host path | `adb reverse` plus app URL `127.0.0.1`, if verified; otherwise do not change settings | Host list mistakes or broad entries can weaken host validation; backend is on collaborator branch | Confirm selected Host is accepted; unrelated Host remains rejected; no wildcard | PENDING |
| REQUIRED before non-development use; deployment choice unresolved | Deployment configuration / approved settings module (none currently identified) | Current inspected settings are development-oriented: `DEBUG=True`; session cookie Secure default is false; no production settings module found | NFR-SEC-02 requires HTTPS in production and secure HttpOnly SameSite cookies; host/deployment configuration is not defined | Define production-style settings: DEBUG off, HTTPS, explicit hosts, secure cookies and reviewed proxy settings | Necessary before any real-device production use, independent of Flutter auth | Do not deploy; retain development-only scope | Misconfigured proxy/TLS/cookie settings can expose traffic or break clients | Deployment security checklist, HTTPS/host rejection, cookie attribute and trusted proxy checks | PENDING |
| NOT NECESSARY for development spike | None | Existing session+CSRF endpoints are routed | Native cookie persistence is untested, but no verified endpoint gap yet | No backend auth change proposed for spike; reconsider only if the approved isolated spike finds a concrete blocker | No new endpoint is needed to test current behavior | Stop and retain web-only auth if SRS or spike is not approved | Mistaking spike success for production readiness | Isolated cookie/CSRF/rotation/logout/revocation test; test design and environment must be separately approved | PENDING |
| OUT OF PHASE 3 AUTH SCOPE | Future module app files | No live service APIs for academic, finance, clearance, announcements, notifications, reports, support, or group rating | SRS functions have no routed APIs; module names/stubs are not endpoints | Separately scope and approve each service API, data model, authorization, privacy, and tests | Necessary only for the corresponding service feature | Keep service screens unavailable | Broad object access, IDOR, privacy and financial risk | Per-service ownership/assignment/period, cross-user, role-combination, and redaction tests | PENDING |

## Spike restrictions and hosting

The session+CSRF spike is **NOT DESIGNED / NOT APPROVED**. The project test
runner creates disposable MySQL databases during test runs; a live server
connected to an isolated database and a scripted identity have not been
designed. Creating a test account is a write and requires separate approval.
No database, account, server, or request was used for this proposal.

“No backend change” applies only to a developer-PC spike using an approved
development path. Any use beyond a developer PC requires production-style
configuration regardless of whether the client uses sessions or tokens.
Hosting/domain and production configuration are unresolved.

`adb reverse` remains unverified: the Phase 2 T6 harness did not record a
usable status and T8 had no physical phone. Direct use of emulator alias
`10.0.2.2` is known to be rejected by current Host validation. Do not treat
reverse forwarding as a proven workaround.

## Related documents

- [Authentication Architecture](AUTHENTICATION_ARCHITECTURE.md)
- [Mobile API Specification](MOBILE_API_SPECIFICATION.md)
- [Phase 3 Inspection Report](../testing/PHASE-3-INSPECTION-REPORT.md)
- [Backend Change Register](../BACKEND_CHANGE_REGISTER.md)
