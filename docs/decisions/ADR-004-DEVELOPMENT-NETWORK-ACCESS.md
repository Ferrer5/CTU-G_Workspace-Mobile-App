# ADR-004: Development Network Access

- **Status:** Accepted for Phase 2 connectivity checks only; no backend or app
  networking implementation approved.
- **Date:** 2026-11-12.

## Context

The Flutter app has no HTTP client or backend calls. The backend's live
development settings use `DEBUG = True` and `ALLOWED_HOSTS = []`. Django's
development fallback accepts localhost/loopback; the emulator alias was
rejected with HTTP 400 during T5. A 400 confirms reachability only.

The Windows Wi-Fi profile observed during the audit was Public. The user
deferred LAN tests until a separately approved Private-profile session. No
physical phone was available. T6 through `adb reverse` did not yield a usable
status and remains inconclusive.

## Decision

- Use host loopback for the backend's Stage A development listener.
- Use the emulator's fixed host alias `10.0.2.2` for direct emulator
  connectivity probes. The alias is not accepted by current backend host
  validation; therefore it is not yet a usable API base URL.
- Treat `adb reverse` as an alternative that is not validated in this phase.
- Do not test LAN/physical-device access on a Public profile. Revisit only
  after explicit user approval and a Private profile.
- Do not change backend `ALLOWED_HOSTS`, CORS, CSRF, HTTPS, firewall, or
  Android manifests in Phase 2.

## Alternatives and consequences

| Option | Benefits | Costs / constraints |
|---|---|---|
| Emulator alias `10.0.2.2` | Fixed emulator-to-host route; T5 verified connectivity even with the server bound to host loopback. | Host header is rejected by current Django settings (HTTP 400); explicit host configuration would be required before API use. Emulator-only. |
| LAN host address | Supports a physical device on the same network. | DHCP address can change; needs a LAN-reachable bind, explicit host validation, same-network access, and an approved firewall/profile. Not tested. Do not record an actual address in tracked files. |
| `adb reverse` + localhost | Can avoid using a workstation LAN address and keep a localhost Host header. | T6 did not produce a usable status. The result-collection method was limited; no conclusion about Django or network behavior is warranted. |

## Backend proposals (record only; not approved or implemented)

1. **Explicit `ALLOWED_HOSTS`** — In the protected backend
   `backend/config/settings.py`, consider an environment-driven list of only
   the hostnames/IPs needed for the selected development path. Use the
   emulator alias only if requests use that Host value; use a development LAN
   address only when the LAN path is approved. Never use `*`.
   **Risk:** incorrect or stale entries cause 400 responses; broad entries
   weaken Host-header protection.
   **Rollback:** restore the previous explicit environment/settings value.
   **Regression tests:** allowed development hosts pass; an unrelated host is
   rejected; production host list is explicit.

2. **Development server bind** — Use loopback for emulator-only checks; use
   `0.0.0.0:8000` only for an explicitly approved LAN test on a Private
   profile, and stop the process immediately after testing.
   **Risk:** the service becomes reachable on interfaces beyond loopback.
   **Rollback:** stop it and return to loopback; do not alter firewall
   settings without separate approval.
   **Regression tests:** verify listener address and that the server is not
   left running after the test.

3. **CORS** — No backend change proposed for the native Flutter client;
   browser CORS does not normally govern native HTTP clients. Add narrowly
   scoped origins only if a browser-based consumer is later confirmed.
   **Risk:** permissive browser origins can expose credentialed flows.
   **Rollback:** remove the new origin setting or restore the previous
   allowlist.
   **Regression tests:** approved web origin succeeds; unapproved origin is
   denied; native client behavior is tested separately.

4. **CSRF and mobile authentication** — Preserve session+CSRF for the browser
   flow. Decide a separate mobile authentication contract in a future phase;
   do not disable CSRF globally.
   **Risk:** bypassing CSRF can expose browser session actions; reusing browser
   sessions on mobile may have unsuitable lifecycle/security behavior.
   **Rollback:** restore the prior CSRF/authentication behavior.
   **Regression tests:** browser unsafe requests still require CSRF; any new
   mobile auth contract has positive, negative, expiry, and authorization
   tests.

5. **Production HTTPS/TLS** — Configure HTTPS termination, explicit
   `ALLOWED_HOSTS`, and trusted proxy/security settings before production.
   Prefer device/system-trusted certificates; use debug-only trust for an
   internal development CA if needed. No certificate pinning is proposed.
   **Risk:** incorrect proxy or certificate configuration can expose traffic
   or break clients.
   **Rollback:** restore the last known-good TLS deployment configuration;
   do not fall back to cleartext production traffic.
   **Regression tests:** HTTPS enforcement, certificate/hostname validation,
   secure cookie attributes, proxy handling, and production host rejection.

## Revisit criteria

Revisit this ADR only after the backend host policy and mobile authentication
contract are approved, the Private-profile LAN path is explicitly authorized
if needed, and the Android cleartext behavior of the selected Dart networking
stack has been tested. No Phase 3 work is authorized by this decision.
