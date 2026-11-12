No backend modifications were made during Phase 1.
No backend modifications were made during Phase 2.

## Phase 3 documentation-only record — 2026-11-12

**No backend change was made in Phase 3.** The existing user-owned
`backend/config/settings.py` two-line first-admin bootstrap flag remained
unchanged. At the start and end of the documentation work, the binary SHA-256
of `git diff --no-ext-diff --binary` was
`E0D855ECC3C086B5E4930C361F6B7A76D2BC172109A158DE6C2CBA58886A2771`;
the backend branch was `ronald`, HEAD `32675e5b5efa6b0ef881d92d78250d9889e4858f`.
This phase did not edit the backend, use its database, start a server, or run
backend tests.

### Pending proposals only

| Proposal | Classification | Approval |
|---|---|---|
| Explicit host allowlist for emulator `10.0.2.2` or LAN in `backend/config/settings.py` | OPTIONAL, conditional on choosing that non-loopback development path; `adb reverse` remains unverified | PENDING |
| Production-style settings (DEBUG off, secure cookies, explicit hosts and HTTPS) | Needed before any non-development use; deployment/hosting decision is pending | PENDING |
| Mobile auth backend change for the proposed session+CSRF spike | NOT NECESSARY for the development spike; revisit only if a verified blocker appears | PENDING |
| Academic, finance, clearance, announcements, notification, reports, support, and group-rating APIs | OUT OF PHASE 3 AUTH SCOPE; each requires separate product/API approval | PENDING |

The proposed Flutter session+CSRF spike is **NOT DESIGNED / NOT APPROVED**.
`config.test_settings` and `config.test_runner` create a disposable MySQL test
database for test runs; a live server connected to a separate test database
and a scripted test identity have not been designed. Creating an account is a
write and needs its own approval. No test account or test database was created.

These proposals do not change the protected backend and do not authorize any
branch or implementation. See
[Phase 3 backend change proposal](architecture/PHASE-3-BACKEND-CHANGE-PROPOSAL.md)
and [Phase 3 inspection report](testing/PHASE-3-INSPECTION-REPORT.md).

# Proposed future changes (NOT implemented)

All proposals below are **Proposed, not approved, not implemented**. They
require a separate backend change approval and regression plan.

| Proposal | Justification and exact location | Risk | Rollback | Regression tests needed |
|---|---|---|---|---|
| Explicit `ALLOWED_HOSTS` | `backend/config/settings.py`: consider an environment-driven explicit list for the approved emulator or LAN host; current live value is empty with DEBUG enabled. Never use `*`. | Wrong/stale entries reject valid clients; broad entries weaken Host-header protection. | Restore the previous explicit environment/settings value. | Approved development host passes; unrelated host fails; production host list stays explicit. |
| Temporary development bind | Start `manage.py runserver` on `0.0.0.0:8000` only for a separately approved LAN test on a Private profile; otherwise retain loopback. This is a run command, not a proposed persistent backend setting. | Listener may become reachable through non-loopback interfaces. | Stop the server and return to loopback. Firewall changes require separate user approval and are not proposed here. | Confirm expected listener address, intended reachability, and server shutdown after testing. |
| CORS policy | No change for a native client unless a browser consumer is confirmed; if needed, configure explicit origins in `backend/config/settings.py`. | Broad origins can expose browser flows, especially with credentials. | Remove the added origin setting or restore the last explicit allowlist. | Approved browser origin succeeds; unapproved origin is denied; native client is tested independently. |
| CSRF and mobile authentication | Preserve browser session+CSRF behavior. Design a separate mobile authentication contract before adding endpoints or changing auth settings. | Disabling CSRF can expose browser session actions; an unsuitable mobile session/token model can weaken authorization. | Restore prior CSRF/auth behavior and remove any new mobile auth route. | Browser unsafe requests remain CSRF-protected; mobile auth tests cover authorization, invalid/expired credentials, and session lifecycle. |
| Production HTTPS/TLS | Configure HTTPS, explicit host validation, and trusted proxy/security settings in backend/deployment configuration before production. | Incorrect TLS/proxy configuration can expose traffic or break clients. | Restore last known-good TLS configuration; do not roll production back to cleartext. | HTTPS redirect/termination, certificate and hostname verification, secure cookie attributes, proxy handling, and invalid-host rejection. |

The live audit and Phase 2 test outcomes are recorded in
[Backend Integration Baseline](architecture/BACKEND_INTEGRATION_BASELINE.md)
and the [Phase 2 Test Report](testing/PHASE-2-TEST-REPORT.md). No mobile
`INTERNET` permission, network client, or authentication implementation was
approved or added in Phase 2.
