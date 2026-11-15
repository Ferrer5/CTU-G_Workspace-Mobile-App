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

## Phase 5 connectivity options — proposal only — 2026-11-15

**Primary demo path:** owner-controlled phone hotspot. **Long-term target:** hosted HTTPS.
This is a proposal only; no backend, firewall, Android, or deployment change is authorized here.
Read-only source inspection found `backend/manage.py` defaults to `config.settings`;
`backend/config/settings.py` has `DEBUG = True`, `ALLOWED_HOSTS = []`, active session and
CSRF middleware, but no explicit `CSRF_*`, `SESSION_*`, `SECURE_*`, or
`CSRF_TRUSTED_ORIGINS` settings. `backend/apps/accounts/session_auth.py` enforces CSRF
for unsafe session API requests. Recovery links use `WORKSPACE_PUBLIC_BASE_URL`
(default `http://localhost:5173`); recovery and SMTP are disabled by default. Keep
session/CSRF checks enabled for every option.

### 1. USB cable with `adb reverse` — debug demos, no backend change

- **Backend:** none. Keep the development server loopback-bound at `127.0.0.1:8000`;
  use the existing `manage.py` development entry point. Do not edit `ALLOWED_HOSTS`.
- **Mobile:** debug build with `API_BASE_URL=http://127.0.0.1:8000/api/v1/`.
  The current debug network-security configuration already permits cleartext only
  for `127.0.0.1` and `localhost`; leave the release policy unchanged.
- **Risk / approval:** Phase 2 `adb reverse` was inconclusive and a physical-phone
  run was not verified. Project owner approves each demo; instructor approval is
  needed if presented as course evidence. No backend approval is needed for this
  path.

### 2. Same Wi-Fi/LAN over HTTP — phone hotspot is primary; school Wi-Fi is risky

- **Backend:** propose an exact laptop hotspot IPv4 host entry in
  `backend/config/settings.py` `ALLOWED_HOSTS` (host only, no scheme or port), and
  bind the development server to `0.0.0.0:8000` for that demo only. A narrowly
  scoped inbound TCP 8000 firewall rule may be needed on the hotspot's Private
  profile; it is a separate, approval-required host change. Do not use `*`.
- **Mobile:** set `API_BASE_URL=http://<laptop-hotspot-ip>:8000/api/v1/` for the
  development environment. A debug-only `android/app/src/debug/AndroidManifest.xml`
  and `android/app/src/debug/res/xml/network_security_config.xml` change would
  permit cleartext only for that exact IP; Android cannot wildcard IP ranges.
  The IP is compiled into the app, so build again if it changes. Keep release
  builds HTTPS-only.
- **Risk / approval:** `0.0.0.0` exposes the listener on interfaces; `DEBUG=True`
  can expose detailed error pages. Hotspot addresses and firewall behavior vary.
  The owner reports Phase 2 public Wi-Fi blocked phone-to-laptop traffic; device
  isolation is common. The saved Phase 2 report marks physical-device/LAN testing
  as not run, so treat that report as unverified evidence until reconciled.
  Project owner and backend maintainer must approve backend settings; owner must
  separately approve firewall/mobile changes. School network use also needs
  school IT approval and is not the recommended demo path.

### 3. Hosted HTTPS — recommended for real use

- **Backend/deployment:** in `backend/config/settings.py` and its deployment
  environment, set `DEBUG=False`, explicit `ALLOWED_HOSTS` for the API domain,
  exact `CSRF_TRUSTED_ORIGINS` where cross-origin browser requests require them,
  `SESSION_COOKIE_SECURE=True`, `CSRF_COOKIE_SECURE=True`, and correctly scoped
  HTTPS redirect/proxy settings. Use a domain or stable address with a trusted
  certificate and a production WSGI server, not `runserver`. Set
  `WORKSPACE_PUBLIC_BASE_URL=https://<web-domain>` and
  `WORKSPACE_EMAIL_PUBLIC_HOSTS` to the approved web hostname so emailed reset
  links open the HTTPS browser reset page. Keep reset enablement and SMTP
  credentials separately approved; never put credentials in the repo.
- **Mobile:** release `API_BASE_URL=https://<api-domain>/api/v1/`; do not allow
  cleartext in release builds. The emailed reset link remains a browser flow;
  no in-app token entry or deep link is proposed.
- **Hosted HTTPS CSRF:** Django validates an `Origin` or, if absent, a `Referer`
  on HTTPS unsafe requests. The mobile client now sends `Origin:
  https://<api-domain>`; the hosted backend must allow the matching origin in
  `CSRF_TRUSTED_ORIGINS`. To be verified in an isolated test.
- **Risk / approval:** hosting, DNS, TLS/proxy configuration, secure cookies,
  CSRF Origin/Referer behavior, and email delivery need deployment/security
  verification. Project owner, instructor/reviewer, backend maintainer, and
  hosting/security and mail-service owners must approve their respective changes.
