# Phase 2 Network Test Report

Date: 2026-11-12. Scope: read-only audit, approved environment examples and
config test, and bounded local development connectivity checks. Tests were
performed only after user approval. The user started and stopped the approved
backend; the assistant did not run backend code.

## Test outcomes

| Test | Command / procedure | Expected | Actual | Status | Evidence |
|---|---|---|---|---|---|
| Environment examples | `dart format`, `flutter analyze`, `flutter test` after adding two tracked examples and a test of every `env/*.example.json` | Examples validate; production placeholder rejected; all tests pass | Formatting check: 12 files, 0 changed. Analyzer: no issues. Test suite: 18 passed. | PASS | Command output summarized here; no raw response data retained. |
| T1: Port free before startup | `Get-NetTCPConnection -LocalPort 8000 -State Listen` before any server start | No listener | No listener present. | PASS | T1 status recorded before startup. |
| T2: Host loopback | `curl.exe -sS --max-time 10 -o NUL -w 'HTTP %{http_code}' http://127.0.0.1:8000/api/v1/auth/session/` | HTTP 200 | `HTTP 200` — host loopback reached the read-only session endpoint. | PASS | Status line and diagnosis only; response body discarded. |
| T3: Bind check | `Get-NetTCPConnection -State Listen -LocalPort 8000` | Exactly one listener at `127.0.0.1` | One listener at `127.0.0.1:8000`. | PASS | Listener address and port only. |
| T4: Host to LAN address | Deferred Stage B test to `<LAN_IPV4>` with default and accepted Host headers | Default Host expected 400; accepted localhost Host expected 200 | Not run. Active Wi-Fi profile was Public; Stage B requires separate approval on a Private profile. | BLOCKED | No LAN address or response body retained. |
| T5: Emulator host alias | Emulator `nc` GET to `10.0.2.2:8000`, with Host `10.0.2.2:8000`; output limited to first status line | HTTP 400 `DisallowedHost` | `HTTP/1.1 400 Bad Request` — emulator reached Django over the host alias; Django rejected the Host as expected. The user reports Django logged `Invalid HTTP_HOST` and returned a detailed DEBUG error page. | PASS | Status line and diagnosis only; debug response body and headers were not retained. |
| T6: Emulator through ADB reverse | `adb reverse tcp:8000 tcp:8000`; bounded emulator GET to localhost with Host `localhost:8000`; then remove mapping | HTTP 200 | No usable HTTP status was recorded in the initial attempts. In the user-approved bounded diagnostic, a reverse mapping was present; emulator `nc` was available, its help indicated `-w`, and the shell supported `pipefail`. The local PowerShell result parser raised `Method invocation failed because [System.Management.Automation.ErrorRecord] does not contain a method named 'Trim'.` before both address attempts could be completed and their status/error/exit captured. The user reports neither attempt appeared in the Django request log. Cause undetermined; method-limited. T5 confirms the emulator-to-host path works without reverse forwarding; it does not validate `adb reverse`. | FAIL | Temporary mapping removed; final `adb reverse --list` contained no mappings. `adb reverse` remains **UNVERIFIED** in this environment until retested in Phase 3. No response body or cookie retained. No further retry authorized. |
| T7: Physical device over LAN | User phone opens `http://<LAN_IPV4>:8000/api/v1/auth/session/` | 400 or a reachability error; connectivity only | Not run. Active Wi-Fi profile was Public; Stage B was deferred. No phone was available. | BLOCKED | No actual LAN address retained. |
| T8: Physical device via USB reverse | Phone request to localhost through `adb reverse` | HTTP 200 | Not run; user reported no physical phone available. | NOT TESTED | No device evidence. |
| T9: Failure modes | Stopped server, wrong address/port, blocked path, rejected Host, unknown route, TLS | Distinct diagnostic symptoms | Not exercised beyond the expected rejected Host in T5. | NOT TESTED | Outside approved Stage A tests. |
| T10: Cleanup and regression | Remove temporary reverse; user stops backend; run format/analyze/tests; protected-repo baseline capture | No temporary reverse or backend listener; checks pass; protected repo unchanged from baseline | User confirmed server stopped and reverse list empty; T10 port check found no listener on 8000. Final format/analyze/tests and protected-repo captures match the authorized baseline. | PASS | Status-only checks; ignored-file status not inspected. |

## Server-window deviation

After T1, the user reported accidentally starting two local instances:

- Approved instance: `127.0.0.1:8000 --noreload`, with
  `PYTHONDONTWRITEBYTECODE=1`, started at 14:24:48.
- Unapproved instance: default `python manage.py runserver`, with
  `StatReloader` and no `PYTHONDONTWRITEBYTECODE` in that window, started at
  14:26:30.

The user reported that both were bound to loopback and stopped both before
starting only the approved instance. No T2/T3/T5/T6 results from the
two-instance period were collected or used. The approved instance was then
confirmed by T2/T3. The unapproved process may have written ignored
`__pycache__` files in the protected backend repository; whether such files
exist was not verified. The final protected-repo check intentionally did not
inspect ignored files because the user asked to do so only if requested.

The user also reports that, at about 14:49–14:50, they viewed Django admin
pages in their own browser on this PC, outside the test plan. The server log
showed GET requests to `/admin/`, `/admin/access_control/accessauditlog/`,
`/admin/accounts/role/` (404), and static resources; no POST, PUT, or DELETE
was seen. `/admin/` returned 200, implying an existing admin session. The user
reports making no changes through the admin. Whether these GETs caused any
session or audit-log database side effects was **NOT VERIFIED**; this activity
is not evidence for any Phase 2 test. No response bodies or headers were
retained.

## Workstation and backend audit

- Active Wi-Fi connection profile: **Public**.
- Domain, Private, and Public Windows firewall profiles were enabled; default
  inbound action was `NotConfigured`.
- Four enabled Python/Python.exe inbound rules were visible on the Public
  profile, covering TCP or UDP on any local port. No firewall rule was added,
  changed, or proposed.
- Before Stage A, no listener was present on ports 8000 or 8080.
- Wi-Fi, a WSL virtual adapter, and a VirtualBox virtual adapter were active;
  no obvious VPN adapter appeared. This does not rule out VPN software or
  tunnels.
- No physical phone was attached. `Medium_Phone` was online as an ADB `device`
  for Stage A. Phase 1 recorded this AVD as API 34; its API level was not
  separately queried during Phase 2. Emulator `curl` was not found on the
  shell path; `/system/bin/nc` and `toybox` were available, and `nc --help`
  indicated support for `-w`.
- The user reported global Python 3.13.7, Django 6.1.2, and DRF 3.18.3, with
  no virtual environment. The Django and DRF versions match the pinned backend
  requirements; Python is a separately user-reported runtime version. The
  assistant did not launch Django, MySQL, or backend code.

Backend facts and line evidence are recorded in
[Backend Integration Baseline](../architecture/BACKEND_INTEGRATION_BASELINE.md).
The selected route is `/api/v1/auth/session/`; it permits GET/HEAD/OPTIONS,
requires no authentication, and does not write or send email.

## Protected repository boundary

The user confirmed that the `backend/config/settings.py` change was theirs and
authorized the corrected capture as the Phase 2 baseline. No backend files
were modified by the assistant.

| Capture | Phase 2 baseline | Final capture | Result |
|---|---|---|---|
| HEAD | `32675e5b5efa6b0ef881d92d78250d9889e4858f` | `32675e5b5efa6b0ef881d92d78250d9889e4858f` | Unchanged |
| `git status --porcelain` | ` M backend/config/settings.py` | ` M backend/config/settings.py` | Unchanged |
| `git diff --stat` | `backend/config/settings.py \| 2 ++` | `backend/config/settings.py \| 2 ++` | Unchanged |
| SHA-256 of raw `git diff` | `E0D855ECC3C086B5E4930C361F6B7A76D2BC172109A158DE6C2CBA58886A2771` | `E0D855ECC3C086B5E4930C361F6B7A76D2BC172109A158DE6C2CBA58886A2771` | Unchanged |

The existing user-owned settings diff was not printed in this report. Ignored
file status was not inspected.

## Security and limitations

- No Stage B LAN request was made because the active profile was Public.
- No firewall, router, adapter, DNS, hosts, or VPN settings were changed.
- The main Android manifest still has no INTERNET permission or cleartext
  configuration. Debug/profile manifests retain their generated development
  INTERNET permission. The release manifest permission status is **not
  verified**.
- The backend used `DEBUG=True`; its 400 invalid-Host response produced a
  detailed debug error page. DEBUG pages can expose detailed error information
  to any client that can reach the server, reinforcing the loopback-only
  development boundary.
- Android cleartext policy applies by default to apps targeting API 28+ unless
  opted in; whether Dart `dart:io` `HttpClient` is governed by that policy in
  this app remains **UNVERIFIED**.
- A successful T2 or T5 status is a transport check, not an API integration.
- Backend modifications: **NONE**.
