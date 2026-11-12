# Phase 2 Network Architecture

Date: 2026-11-12. This records a development connectivity assessment only.
Phase 2 did not add an API client or change the backend.

## Current topology and observed state

```text
Windows host
  Django development server on 127.0.0.1:8000
    ├── host loopback request: HTTP 200 on /api/v1/auth/session/
    ├── Android Emulator host alias 10.0.2.2: HTTP 400 DisallowedHost
    └── adb reverse to emulator localhost: T6 not verified

Physical device over LAN: not tested
```

The emulator was online in ADB for Stage A. The user started and stopped the
server, and the final port check found no listener. The selected session route
is read-only and requires no request body; the test captured only HTTP status
lines. A 400 from an unaccepted Host value confirms a request reached Django,
not that an API integration works.

| Path | Addressing and prerequisite | Phase 2 evidence |
|---|---|---|
| Host to backend | `127.0.0.1:8000`; server bound to loopback | T2 returned HTTP 200; T3 observed one loopback listener. |
| Android Emulator to host | Emulator host alias `10.0.2.2`; host listener must be reachable | T5 returned HTTP 400 because Django rejected that Host value. This demonstrates connectivity, not API usability. |
| Emulator through USB/debug bridge | `adb reverse tcp:8000 tcp:8000`, then emulator localhost | T6 failed to produce a usable status. Cause is undetermined and method-limited; it is not evidence that Django or the network path is broken. Temporary mapping was removed and the final reverse list was empty. |
| Physical device to host LAN address | Same LAN, host listening on a LAN-reachable interface, and an approved network/firewall state | Not tested. The observed Wi-Fi profile was Public; Stage B was deferred. No actual LAN address is recorded here. |
| Physical device through USB reverse | USB debugging and an attached phone, with `adb reverse` | Not tested; no physical phone was available. |

`10.0.2.2` is the Android Emulator's special alias to the host loopback
interface. Emulator `localhost` is the emulator itself, not the Windows host.
The successful T5 response through the host alias with a loopback-only server
is evidence for this emulator configuration. Do not generalize it to a
physical device.

## Backend host validation and route

The live audit found Django `DEBUG = True` and `ALLOWED_HOSTS = []`. Django's
documented development fallback accepts localhost and loopback when DEBUG is
enabled and ALLOWED_HOSTS is empty. The observed T2 loopback response was HTTP
200. T5's `10.0.2.2` Host was rejected with HTTP 400. Never use `ALLOWED_HOSTS
= ['*']` as a connectivity workaround.

The connectivity probe used `GET /api/v1/auth/session/`. It is routed to
`SessionView`, permits GET/HEAD/OPTIONS, allows unauthenticated requests, and
reads the current session without writing to the database or sending email.
An authenticated session may cause database reads to construct a status
response. Routes and methods are detailed in
[Backend Integration Baseline](BACKEND_INTEGRATION_BASELINE.md).

## Development versus production boundary

- The Phase 2 backend test used temporary local HTTP on host loopback only.
- Stage B LAN testing was not run: the active Wi-Fi profile was Public and the
  user required separate approval on a Private profile. Four enabled Python /
  Python.exe inbound rules were observed on the Public profile, allowing TCP
  or UDP on any local port. No firewall changes or proposals were made.
- A future LAN-only development server would need an explicit, reviewed bind
  and host allowlist. It must not be exposed on a Public network. The user
  must approve any firewall change before one is proposed or made.
- Production requires HTTPS, explicit `ALLOWED_HOSTS`, and correctly configured
  trusted-proxy/security settings. Do not infer production readiness from a
  local HTTP status.
- CORS is a browser policy; a native Flutter HTTP client normally does not
  require browser CORS headers. Keep CORS restricted if a browser consumer
  needs it. Phase 2 made no CORS change.
- The existing backend uses browser session + CSRF protections. Mobile
  authentication and its token/session contract remain a separate Phase 3
  decision; do not disable CSRF to make a mobile test work.

## Android cleartext and certificate design

Android's network security policy documents cleartext HTTP as disabled by
default for apps targeting API 28 and later, unless the app opts in. Flutter's
networking guide documents the Android INTERNET manifest permission.
Whether Dart `dart:io` `HttpClient` in this app is governed by that Android
cleartext policy is **UNVERIFIED** and must be tested in Phase 3 on the actual
build/runtime before choosing a configuration.

Phase 3 design only (not implemented): if development HTTP is required, use a
debug-variant-only network security configuration scoped to approved
development hosts. Do not add a cleartext opt-in or networking permission to
the main manifest without separate approval. Confirm the release variant
independently; its manifest permission status remains unverified.

For HTTPS, prefer certificates trusted by the device's system CA store. If an
internal development CA is necessary, limit trust to a debug-only build and
the intended development hosts. Do not disable certificate validation or add
certificate pinning in this phase.

## Security and verification limits

- A 400 `DisallowedHost` is useful connectivity evidence, but is not a
  successful API call.
- Wi-Fi was Public. Stage B LAN tests and physical-device tests are therefore
  not evidence-backed.
- The active adapters included WSL and VirtualBox virtual adapters. No obvious
  VPN adapter was observed; VPN software/tunnels were not exhaustively ruled
  out.
- The unapproved second server instance described in the test report may have
  written ignored `__pycache__` files in the protected backend repository.
  Their presence was not checked.
- The user reports viewing Django admin pages in their own browser outside the
  test plan. The requests were GETs; the user reports making no admin changes.
  Whether GETs caused session or audit-log database side effects was not
  verified. They are not test evidence.
- `DEBUG=True` produced a detailed error page for an invalid Host. Such pages
  can expose error details to any client that can reach the server; keep the
  development server loopback-only.
- No response bodies, cookies, actual LAN IPv4 values, or Wi-Fi name were
  retained in the repository.
- T6 is method-limited and inconclusive. T5 independently confirms the
  emulator-to-host path without reverse forwarding.
- No API client, authentication, deployment, firewall, manifest, or backend
  changes were made.

## Official references

- [Android Emulator networking](https://developer.android.com/studio/run/emulator-networking)
- [Android Network Security Configuration](https://developer.android.com/privacy-and-security/security-config)
- [Android NetworkSecurityPolicy](https://developer.android.com/reference/android/security/NetworkSecurityPolicy#isCleartextTrafficPermitted())
- [Flutter networking and Android INTERNET permission](https://docs.flutter.dev/data-and-backend/networking)
- [Dart `HttpClient`](https://api.dart.dev/dart-io/HttpClient-class.html)
- [Django 6.1 `ALLOWED_HOSTS`](https://docs.djangoproject.com/en/6.1/ref/settings/#allowed-hosts)
- [Android Debug Bridge](https://developer.android.com/tools/adb)
