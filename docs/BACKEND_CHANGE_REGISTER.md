No backend modifications were made during Phase 1.
No backend modifications were made during Phase 2.

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
