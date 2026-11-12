# Local Network Setup

This is a development-only runbook. It does not configure the backend, app,
Windows firewall, Wi-Fi, or VPN. The backend is in a separate protected
repository and must be started and stopped by its owner.

## Emulator setup (Stage A)

1. Start the local MySQL service yourself.
2. Start the existing `Medium_Phone` emulator yourself. Confirm
   `adb devices -l` lists its serial with state `device`. Do not restart ADB or
   launch the emulator as part of this runbook.
3. Use the tracked [emulator example](../../env/dev.emulator.example.json) as
   the configuration source, copying it to the ignored local `env/dev.json`
   only if you intend to run the app. It targets the fixed emulator alias and
   development port, not a workstation LAN address.
4. Start the Django server from the backend checkout, in the user's own
   PowerShell. Use bytecode suppression and no reloader:

   ```powershell
   Set-Location '<backend checkout>\backend'
   $env:PYTHONDONTWRITEBYTECODE = '1'
   python manage.py runserver 127.0.0.1:8000 --noreload
   ```

   The user reported global Python 3.13.7 with Django 6.1.2 and DRF 3.18.3,
   with no virtual environment. Those versions match the pinned backend
   requirements observed in the Phase 2 audit. Do not run this command from
   the mobile repository or ask an assistant to start the backend.
5. After the owner confirms the server is started, the approved Stage A
   probes are:

   ```powershell
   Get-NetTCPConnection -LocalPort 8000 -State Listen
   curl.exe -sS --max-time 10 -o NUL -w 'HTTP %{http_code}' http://127.0.0.1:8000/api/v1/auth/session/
   adb -s emulator-5554 shell 'printf "GET /api/v1/auth/session/ HTTP/1.0\r\nHost: 10.0.2.2:8000\r\nConnection: close\r\n\r\n" | nc -w 10 10.0.2.2 8000 | toybox head -n 1'
   ```

   Retain only the HTTP status line, exit code, and one-line diagnosis. Do not
   retain response bodies or cookies. A 400 for the emulator alias is expected
   with the current empty `ALLOWED_HOSTS`; it confirms transport reachability,
   not API usability.
6. T6 via `adb reverse tcp:8000 tcp:8000` did not yield a reliable result in
   Phase 2. Its cause is undetermined and method-limited. Do not treat it as
   proof of a Django or network failure. If separately authorized in a future
   test, use an explicit timeout and remove the mapping afterwards:

   ```powershell
   adb -s emulator-5554 reverse tcp:8000 tcp:8000
   adb -s emulator-5554 reverse --list
   # Make one bounded emulator request to localhost:8000 with Host: localhost:8000.
   adb -s emulator-5554 reverse --remove tcp:8000
   adb -s emulator-5554 reverse --list
   ```

7. The user stops the backend with Ctrl+C when finished.

## Physical device and LAN (Stage B; not approved or tested)

Stage B requires separate user approval, a Private Windows network profile,
and a phone on the same non-isolated network. The observed active profile was
Public, so no LAN request was made. Do not switch profiles or alter firewall,
router, adapter, DNS, hosts, or VPN settings as part of this runbook. No
firewall command is proposed here.

If Stage B is approved later, use an explicitly approved LAN-reachable
listener and an explicitly configured host allowlist. Use `<LAN_IPV4>` as a
placeholder in instructions; never commit a real workstation address.
`ALLOWED_HOSTS` currently rejects non-loopback hosts, so a 400 may demonstrate
reachability but does not mean the backend is ready for an app integration.

The physical-device example
[dev.device.example.json](../../env/dev.device.example.json) uses the
documentation-only address `192.0.2.10`; replace it only in a local ignored
configuration after the required approval. It is not a usable server address.

## Troubleshooting boundaries

- `localhost` on Android refers to the device/emulator, not the Windows host.
- `10.0.2.2` is an emulator-only host alias; a physical phone uses a
  LAN-reachable host address and requires same-network reachability.
- A Django 400 `DisallowedHost` means Django received a request with an
  unaccepted Host header; it is not a successful API response.
- A refused connection usually means no listener at that address/port;
  timeouts can also result from network isolation, firewall policy, or VPN
  routing.
- Do not infer cleartext or app permission behavior from browser/curl probes.
  Dart `HttpClient` behavior on the target Android build remains unverified.
- This runbook tests connectivity only. It does not implement API integration.
