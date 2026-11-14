# PHASE 4A — Spike runbook (preparation only)

## Status

**Status:** PROPOSED / NOT APPROVED.  
**SRS addendum:** NOT signed in the repository; its signature lines are blank and it still contains `[YOUR NAME]` / `[TEACHER NAME]` placeholders.  
**Execution:** This is documentation only. The user must run every command. Nothing in this runbook has been run, started, created, or installed as part of this preparation.

## Scope and safety

- The backend's built-in sandbox uses the dedicated MySQL database `ctug_review_sandbox`; never use `ctug_workspace`.
- Run the backend only on `127.0.0.1:8001`; do not bind to `0.0.0.0` or a public interface.
- Use `config.review_sandbox_settings`, which requires `CTUG_REVIEW_SANDBOX_ACK=SANDBOX_ONLY`, sets the sandbox database and cookie names, limits `ALLOWED_HOSTS` to `127.0.0.1` and `localhost`, and installs loopback-only middleware.
- Do not set or rely on `DJANGO_SETTINGS_MODULE`; pass `--settings=config.review_sandbox_settings` explicitly on every `manage.py` command.
- Use `python -B` and set `PYTHONDONTWRITEBYTECODE=1` to avoid writing Python bytecode.
- Never put a database password or sandbox password on a command line. MySQL's `-p` and the seed command prompt interactively.
- If your MySQL installation, user, or privilege setup is unclear, stop and clarify it before running these steps.

## 1. Create the sandbox database

The MySQL account used by Django needs privileges sufficient for migrations and the sandbox seed, limited to `ctug_review_sandbox`. Have a MySQL administrator create the schema and grant the backend's local DB user access to that schema. Do not grant access to `ctug_workspace` for this test.

The sandbox MySQL user is the username configured as `DB_USER` in the backend's `.env`. Do not read or print `.env` contents to obtain it. If you want help tailoring the grant command, provide the `DB_USER` username only—never the password or `.env` contents.

From PowerShell, use an interactive password prompt:

```powershell
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS ctug_review_sandbox CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
```

If a dedicated local MySQL user needs database-scoped privileges, an administrator can use:

```powershell
mysql -u root -p -e "GRANT ALL PRIVILEGES ON ctug_review_sandbox.* TO 'YOUR_MYSQL_USER'@'localhost'; FLUSH PRIVILEGES;"
```

Replace `YOUR_MYSQL_USER` with the `DB_USER` username configured for Django. The MySQL server prompts for the administrator password; do not append it to the command. Confirm that the Django local environment points to the local MySQL host and uses the sandbox-capable account. Do not paste credentials into this runbook or commit them.

## 2. Configure and prepare the backend sandbox

Open PowerShell and change to the backend directory:

```powershell
Set-Location 'C:\Users\Janrey\CTU-G_Workspace\backend'
$env:PYTHONDONTWRITEBYTECODE = '1'
$env:CTUG_REVIEW_SANDBOX_ACK = 'SANDBOX_ONLY'
Remove-Item Env:DJANGO_SETTINGS_MODULE -ErrorAction SilentlyContinue
```

Do not set `DJANGO_SETTINGS_MODULE`; every Django command below specifies its settings module explicitly. Ensure the backend's local environment has the required `DJANGO_SECRET_KEY` and local MySQL connection values. Do not put secret values in command arguments.

### 2.1 Migrate the sandbox schema

Run migrations against the sandbox settings module before seeding:

```powershell
python -B manage.py migrate --settings=config.review_sandbox_settings --noinput
```

### 2.2 Preview the seed (no writes)

The seed command's preview behavior is its default. Do not pass a `--preview` flag:

```powershell
python -B manage.py seed_review_sandbox --settings=config.review_sandbox_settings
```

Expected preview output indicates a fresh schema and that no writes were executed. Stop if it reports an unexpected database or existing application rows.

### 2.3 Apply the seed (only when separately authorized)

The apply operation writes synthetic records and requires the explicit confirmation string. It prompts for the sandbox admin password and confirmation; enter a unique demo-only password at those prompts:

```powershell
python -B manage.py seed_review_sandbox --apply --confirm CTUG-REVIEW-SANDBOX-SEED-ONLY --settings=config.review_sandbox_settings
```

Expected accounts from the source command:

- `SANDBOX-ADMIN-001` — approved, active Admin
- `SANDBOX-STUDENT-PENDING-001` — pending Student request
- `SANDBOX-INSTRUCTOR-PENDING-001` — pending Instructor request
- `SANDBOX-STUDENT-ACTIVE-001` — approved, active Student

The seed source uses the interactively entered password for these synthetic accounts. Keep it only in memory or a temporary secure prompt as described below.

### 2.4 Start the sandbox server

In the same PowerShell session, start the server on loopback only:

```powershell
python -B manage.py runserver 127.0.0.1:8001 --noreload --settings=config.review_sandbox_settings
```

Leave this terminal open while testing. Do not bind to another interface.

### 2.5 Throttle limits and retry behavior

Source limits are registration `5/min` and `30/day`, and login `8/min` and `40/hour`. The project settings do not define a `CACHES` override, so Django's default `LocMemCache` applies. A `429` in the results means the request was throttled, not that the case itself failed. Wait at least 65 seconds before rerunning a throttled short-window case, or stop and restart the sandbox server to reset its in-memory cache; do not change the daily/hourly limits.

## 3. Run API checks from a separate temporary directory

The following script uses one cookie jar, extracts `csrfToken` from the bootstrap JSON, reads the current sandbox CSRF cookie from the jar before every non-GET request, and sends request bodies from temporary JSON files. The password is prompted using `Read-Host -AsSecureString`; it is not typed into a command argument or saved in a script file. Temporary request JSON files contain the sandbox password, and the cookie jar contains session credentials. Restrict access to the temporary folder and delete it during cleanup.

Save the script below outside both repositories as `C:\Temp\ctug_review_sandbox_checks\run-checks.ps1`, then run it in regular PowerShell (not PowerShell ISE). For example:

```powershell
& 'C:\Temp\ctug_review_sandbox_checks\run-checks.ps1'
```

It does not start the backend or create the database.

```powershell
$ErrorActionPreference = 'Stop'
$work = 'C:\Temp\ctug_review_sandbox_checks'
New-Item -ItemType Directory -Path $work -Force | Out-Null
$base = 'http://127.0.0.1:8001'
$jar = Join-Path $work 'cookies.txt'
New-Item -ItemType File -Path $jar -Force | Out-Null

function ConvertTo-PlainText([System.Security.SecureString] $SecureValue) {
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureValue)
    try { [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
}

function Get-CookieValue([string] $Name) {
    foreach ($line in Get-Content -LiteralPath $jar) {
        if (-not $line) { continue }
        if ($line.StartsWith('#HttpOnly_')) { $line = $line.Substring(10) }
        elseif ($line.StartsWith('#')) { continue }
        $parts = $line -split "`t"
        if ($parts.Count -ge 7 -and $parts[5] -eq $Name) { return $parts[6] }
    }
    return $null
}

function Write-JsonBody([string] $Name, $Value) {
    $path = Join-Path $work ($Name + '.json')
    $json = ConvertTo-Json -InputObject $Value -Depth 8 -Compress
    [IO.File]::WriteAllText($path, $json, [System.Text.UTF8Encoding]::new($false))
    return $path
}

function Invoke-Api([string] $Name, [string] $Method, [string] $Path,
                    [string] $BodyPath = '', [switch] $NoCsrf,
                    [string] $CookieOverride = '') {
    $response = Join-Path $work ($Name + '.response.json')
    $headers = Join-Path $work ($Name + '.headers.txt')
    $curlArgs = @('-sS', '-o', $response, '-D', $headers, '-w', '%{http_code}',
                  '-X', $Method, '-c', $jar,
                  '-H', 'Accept: application/json')
    if ($CookieOverride) { $curlArgs += @('-b', $CookieOverride) }
    else { $curlArgs += @('-b', $jar) }
    if ($Method -ne 'GET') {
        $token = Get-CookieValue 'ctug_review_sandbox_csrf'
        if (-not $token) { throw 'No sandbox CSRF cookie available.' }
        if (-not $NoCsrf) { $curlArgs += @('-H', "X-CSRFToken: $token") }
    }
    if ($BodyPath) {
        $curlArgs += @('-H', 'Content-Type: application/json',
                       '--data-binary', ('@' + $BodyPath))
    }
    $curlArgs += ($base + $Path)
    $status = & curl.exe @curlArgs
    $exitCode = $LASTEXITCODE
    [pscustomobject]@{
        Name = $Name
        HttpStatus = [string]$status
        CurlExitCode = $exitCode
        ResponseFile = $response
        HeadersFile = $headers
    }
}

function Show-Result($Result) {
    $Result | Format-List
    if (Test-Path $Result.ResponseFile) {
        Get-Content -LiteralPath $Result.ResponseFile -Raw
    }
}

$securePassword = Read-Host 'Enter the unique sandbox password' -AsSecureString
$password = ConvertTo-PlainText $securePassword

try {
    # 1. CSRF bootstrap; parse the returned csrfToken and confirm the CSRF cookie exists.
    $r = Invoke-Api 'csrf-bootstrap' 'GET' '/api/v1/auth/csrf/'
    Show-Result $r
    $csrfJson = Get-Content (Join-Path $work 'csrf-bootstrap.response.json') -Raw | ConvertFrom-Json
    if (-not $csrfJson.csrfToken -or -not (Get-CookieValue 'ctug_review_sandbox_csrf')) {
        throw 'CSRF bootstrap did not return a token and cookie.'
    }

    # 2. Login as the seeded admin; save body in a temporary JSON file, not a command argument.
    $adminBody = Write-JsonBody 'login-admin' @{
        school_id = 'SANDBOX-ADMIN-001'; password = $password
    }
    $sessionBefore = Get-CookieValue 'ctug_review_sandbox_session'
    $csrfBeforeLogin = Get-CookieValue 'ctug_review_sandbox_csrf'
    $r = Invoke-Api 'login-admin' 'POST' '/api/v1/auth/login/' $adminBody
    Show-Result $r
    $sessionAfter = Get-CookieValue 'ctug_review_sandbox_session'
    $csrfAfterLogin = Get-CookieValue 'ctug_review_sandbox_csrf'
    "Session value changed on login: $($sessionBefore -ne $sessionAfter)"
    "CSRF cookie changed on login: $($csrfBeforeLogin -ne $csrfAfterLogin)"

    # 3. Cookie persistence and session restoration, using the same cookie jar.
    $r = Invoke-Api 'admin-session' 'GET' '/api/v1/auth/session/'
    Show-Result $r
    $r = Invoke-Api 'admin-session-repeat' 'GET' '/api/v1/auth/session/'
    Show-Result $r

    # 4. Logout must use the current CSRF cookie re-read after login.
    $r = Invoke-Api 'logout-admin' 'POST' '/api/v1/auth/logout/'
    Show-Result $r
    $r = Invoke-Api 'session-after-logout' 'GET' '/api/v1/auth/session/'
    Show-Result $r

    # 5. Login as the seeded approved Student account.
    $studentBody = Write-JsonBody 'login-active-student' @{
        school_id = 'SANDBOX-STUDENT-ACTIVE-001'; password = $password
    }
    $r = Invoke-Api 'login-active-student' 'POST' '/api/v1/auth/login/' $studentBody
    Show-Result $r
    $r = Invoke-Api 'active-student-session' 'GET' '/api/v1/auth/session/'
    Show-Result $r

    # 6. Pause and run the role-revocation command in a second backend terminal.
    Read-Host 'Run the role-revocation command in section 3.1, then press Enter'
    $r = Invoke-Api 'session-after-role-revocation' 'GET' '/api/v1/auth/session/'
    Show-Result $r

    # 7. Log in as admin, pause for sandbox-only deactivation, then check session.
    $r = Invoke-Api 'login-admin-for-deactivation' 'POST' '/api/v1/auth/login/' $adminBody
    Show-Result $r
    Read-Host 'Run the account-deactivation command in section 3.1, then press Enter'
    $r = Invoke-Api 'session-after-deactivation' 'GET' '/api/v1/auth/session/'
    Show-Result $r

    # 8. Invalid credentials.
    $badBody = Write-JsonBody 'login-invalid' @{
        school_id = '0000000'; password = 'deliberately-wrong'
    }
    $r = Invoke-Api 'invalid-credentials' 'POST' '/api/v1/auth/login/' $badBody
    Show-Result $r

    # 9. Login attempts for the two seeded Pending users.
    foreach ($id in @('SANDBOX-STUDENT-PENDING-001',
                      'SANDBOX-INSTRUCTOR-PENDING-001')) {
        $body = Write-JsonBody ('login-pending-' + $id) @{
            school_id = $id; password = $password
        }
        $r = Invoke-Api ('login-pending-' + $id) 'POST' '/api/v1/auth/login/' $body
        Show-Result $r
    }

    # 10. Missing CSRF token: explicit no-token POST; expect 403 csrf_failed.
    $missingCsrfBody = Write-JsonBody 'missing-csrf' @{
        school_id = 'SANDBOX-ADMIN-001'; password = $password
    }
    $r = Invoke-Api 'missing-csrf' 'POST' '/api/v1/auth/login/' $missingCsrfBody -NoCsrf
    Show-Result $r

    # 11. Expired/invalid session: request with a deliberately invalid sandbox session cookie.
    $r = Invoke-Api 'invalid-session' 'GET' '/api/v1/auth/session/' `
        -CookieOverride 'ctug_review_sandbox_session=invalid'
    Show-Result $r

    # 12. Sign Up success: use a unique 7-digit numeric school_id.
    $newId = Get-Random -Minimum 1000000 -Maximum 9999999
    $signupBody = Write-JsonBody 'signup-success' @{
        school_id = [string]$newId
        email = "sandbox-$newId@example.invalid"
        first_name = 'Sandbox'
        middle_name = ''
        last_name = 'Applicant'
        suffix = ''
        requested_role = 'Student'
        password = $password
        password_confirmation = $password
    }
    $r = Invoke-Api 'signup-success' 'POST' '/api/v1/auth/register/' $signupBody
    Show-Result $r

    # 13. Duplicate sign up: replay the body; expect the same generic 202 acknowledgement.
    $r = Invoke-Api 'signup-duplicate' 'POST' '/api/v1/auth/register/' $signupBody
    Show-Result $r

    # 14. Login as the newly registered Pending account; expect 401 invalid_credentials.
    $newLoginBody = Write-JsonBody 'login-new-pending' @{
        school_id = [string]$newId; password = $password
    }
    $r = Invoke-Api 'login-new-pending' 'POST' '/api/v1/auth/login/' $newLoginBody
    Show-Result $r

    # 15. Password mismatch; expect 400 validation_error.
    $mismatch = @{
        school_id = [string](Get-Random -Minimum 1000000 -Maximum 9999999)
        email = 'mismatch@example.invalid'; first_name = 'Sandbox'
        last_name = 'Applicant'; requested_role = 'Student'
        password = $password; password_confirmation = 'not-the-same-password'
    }
    $r = Invoke-Api 'signup-password-mismatch' 'POST' '/api/v1/auth/register/' `
        (Write-JsonBody 'signup-password-mismatch' $mismatch)
    Show-Result $r

    # 16. Invalid role; expect 400 validation_error.
    $invalidRole = @{
        school_id = [string](Get-Random -Minimum 1000000 -Maximum 9999999)
        email = 'invalid-role@example.invalid'; first_name = 'Sandbox'
        last_name = 'Applicant'; requested_role = 'Admin'
        password = $password; password_confirmation = $password
    }
    $r = Invoke-Api 'signup-invalid-role' 'POST' '/api/v1/auth/register/' `
        (Write-JsonBody 'signup-invalid-role' $invalidRole)
    Show-Result $r

    # Registration's burst limit is 5/min; pause before the remaining signup requests.
    Start-Sleep -Seconds 65

    # 17. Extra fields are rejected; expect 400 validation_error.
    $extraField = @{
        school_id = [string](Get-Random -Minimum 1000000 -Maximum 9999999)
        email = 'extra-field@example.invalid'; first_name = 'Sandbox'
        last_name = 'Applicant'; requested_role = 'Student'
        password = $password; password_confirmation = $password
        is_active = $true
    }
    $r = Invoke-Api 'signup-extra-field' 'POST' '/api/v1/auth/register/' `
        (Write-JsonBody 'signup-extra-field' $extraField)
    Show-Result $r

    # 18. School ID rule: an eight-digit ID is too long.
    $badSchoolId = @{
        school_id = '12345678'; email = 'bad-school-id@example.invalid'
        first_name = 'Sandbox'; last_name = 'Applicant'; requested_role = 'Student'
        password = $password; password_confirmation = $password
    }
    $r = Invoke-Api 'signup-school-id-too-long' 'POST' '/api/v1/auth/register/' `
        (Write-JsonBody 'signup-invalid-school-id' $badSchoolId)
    Show-Result $r

    # 19. A non-digit school ID is invalid even when its length is within range.
    $nonDigitSchoolId = @{
        school_id = '12345A'; email = 'nondigit-school-id@example.invalid'
        first_name = 'Sandbox'; last_name = 'Applicant'; requested_role = 'Student'
        password = $password; password_confirmation = $password
    }
    $r = Invoke-Api 'signup-school-id-nondigit' 'POST' '/api/v1/auth/register/' `
        (Write-JsonBody 'signup-school-id-nondigit' $nonDigitSchoolId)
    Show-Result $r

    # 20. Missing-CSRF sign up; expect 403 csrf_failed.
    $r = Invoke-Api 'signup-missing-csrf' 'POST' '/api/v1/auth/register/' `
        $signupBody -NoCsrf
    Show-Result $r

    # 21. Server-down check: port 1 is expected to have no listener.
    $savedBase = $base
    $base = 'http://127.0.0.1:1'
    try {
        $r = Invoke-Api 'server-down' 'GET' '/api/v1/auth/session/'
        Show-Result $r
    } catch {
        "Expected server-down exception: $($_.Exception.Message)"
    } finally {
        $base = $savedBase
    }
}
finally {
    $password = $null
    if ($securePassword) { $securePassword.Dispose() }
    $securePassword = $null
}
```

The script prints each HTTP result and response for the user to record. It does not make assertions that convert an unexpected result into a pass. Do not paste passwords, cookies, or sensitive response data into project documentation.

### 3.1 Sandbox-only account state commands

The script pauses for these commands. In a second PowerShell window, set the same two environment variables and change to the backend directory as in section 2. Run each command only when the test script reaches its matching prompt. Both commands verify the configured database and the actual selected MySQL schema before changing data:

**Role revocation** (after the active Student login):

```powershell
Set-Location 'C:\Users\Janrey\CTU-G_Workspace\backend'
$env:PYTHONDONTWRITEBYTECODE = '1'
$env:CTUG_REVIEW_SANDBOX_ACK = 'SANDBOX_ONLY'
Remove-Item Env:DJANGO_SETTINGS_MODULE -ErrorAction SilentlyContinue
@'
from django.conf import settings
from django.db import connection, transaction
from django.db.models.deletion import ProtectedError
from apps.access_control.models import AccountRole, Role

assert settings.DATABASES["default"]["NAME"] == "ctug_review_sandbox"
cursor = connection.cursor()
cursor.execute("SELECT DATABASE()")
assert cursor.fetchone()[0] == "ctug_review_sandbox"
assignments = AccountRole.objects.filter(
    account__school_id="SANDBOX-STUDENT-ACTIVE-001",
    role__role_name="Student",
)
assert assignments.count() == 1
try:
    with transaction.atomic():
        assignments.delete()
except ProtectedError:
    student_role = Role.objects.get(role_name="Student")
    student_role.is_active = False
    student_role.save(update_fields=["is_active"])
'@ | python -B manage.py shell --settings=config.review_sandbox_settings
```

**Account deactivation** (after the admin login):

```powershell
Set-Location 'C:\Users\Janrey\CTU-G_Workspace\backend'
$env:PYTHONDONTWRITEBYTECODE = '1'
$env:CTUG_REVIEW_SANDBOX_ACK = 'SANDBOX_ONLY'
Remove-Item Env:DJANGO_SETTINGS_MODULE -ErrorAction SilentlyContinue
@'
from django.conf import settings
from django.db import connection
from apps.accounts.models import Account

assert settings.DATABASES["default"]["NAME"] == "ctug_review_sandbox"
cursor = connection.cursor()
cursor.execute("SELECT DATABASE()")
assert cursor.fetchone()[0] == "ctug_review_sandbox"
account = Account.objects.get(school_id="SANDBOX-ADMIN-001")
assert account.is_active
account.is_active = False
account.save(update_fields=["is_active"])
'@ | python -B manage.py shell --settings=config.review_sandbox_settings
```

### Expected results

| Check | Expected result |
|---|---|
| CSRF bootstrap | HTTP 200 JSON with `csrfToken`; sandbox CSRF cookie present |
| Admin login | HTTP 200, `authenticated: true`; session cookie changes on login |
| Cookie persistence / session check | Reusing the same jar returns `authenticated: true` while the account remains eligible |
| Logout | HTTP 200, `authenticated: false`; next session check is unauthenticated |
| Approved active Student login | HTTP 200, `authenticated: true` |
| Invalid credentials | HTTP 401 with `error.code = "invalid_credentials"` |
| Seeded Pending account login | HTTP 401 with generic `invalid_credentials` |
| Newly registered Pending account login | Sign-up returns HTTP 202; subsequent login returns HTTP 401 `invalid_credentials` |
| Missing CSRF on login or sign-up | HTTP 403 with `error.code = "csrf_failed"` |
| Expired/invalid session cookie | HTTP 200 with `authenticated: false` |
| Role revocation in sandbox DB | Existing student session check returns `authenticated: false` |
| Account deactivation in sandbox DB | Existing admin session check returns `authenticated: false` |
| Sign-up success | HTTP 202 and the pending-review acknowledgement |
| Duplicate sign-up | HTTP 202 with the same generic acknowledgement; no second account is created |
| Password mismatch | HTTP 400 validation error |
| Invalid requested role | HTTP 400 validation error |
| Extra sign-up field | HTTP 400 validation error; unsupported fields rejected |
| School ID too long | HTTP 400 validation error; maximum 7 digits |
| School ID contains non-digits | HTTP 400 validation error; digits only |
| Server down | Curl connection failure/nonzero exit; no success-shaped auth state |

Malformed-response handling belongs in the Flutter mocked tests, not this backend spike.
If any check returns HTTP 429, record it as throttled and not as a failure of that case; wait at least 65 seconds before retrying or restart the sandbox server to reset its LocMemCache.

## 4. Emulator adb reverse retest and Android cleartext

Both `adb reverse` behavior and Android app cleartext behavior are **UNVERIFIED**. If the app requires any manifest or network-security configuration change, stop and get separate approval before making it.

### 4.1 Retest the adb reverse path

With the sandbox server running on the host's `127.0.0.1:8001`, run on the host:

```powershell
adb reverse tcp:8001 tcp:8001
adb reverse -list
adb shell am start -a android.intent.action.VIEW -d "http://127.0.0.1:8001/api/v1/auth/session/"
```

The last command opens the URL in the emulator's browser. Confirm that the browser displays the API response rather than a connection error. This verifies only that the emulator's loopback address is forwarded to the host loopback server. It does **not** prove that the Flutter app can make cleartext HTTP requests, nor does it test app cookie persistence.

Remove the reverse mapping after the check:

```powershell
adb reverse --remove tcp:8001
adb reverse -list
```

### 4.2 Android cleartext check

Whether the Android app can make HTTP requests to this loopback path is separately unverified. Browser reachability through `adb reverse` is not evidence of Flutter/Dart app cleartext permission. If the actual app test fails and a manifest or network-security config change appears necessary, stop and request explicit approval; do not modify Android configuration under this runbook.

## 5. Cleanup

Stop the server with `Ctrl+C` in its terminal. Then drop only the sandbox database using an interactive MySQL password prompt:

```powershell
mysql -u root -p -e "DROP DATABASE IF EXISTS ctug_review_sandbox;"
```

If using a different MySQL administrator, replace `root` with that account. Remove test-only environment variables from each backend PowerShell session (including the second window used for state-change commands):

```powershell
Remove-Item Env:DJANGO_SETTINGS_MODULE -ErrorAction SilentlyContinue
Remove-Item Env:CTUG_REVIEW_SANDBOX_ACK -ErrorAction SilentlyContinue
Remove-Item Env:PYTHONDONTWRITEBYTECODE -ErrorAction SilentlyContinue
```

Delete the temporary test directory only after confirming it contains no files you want to retain:

```powershell
Get-ChildItem -LiteralPath 'C:\Temp\ctug_review_sandbox_checks' -Force
Remove-Item -LiteralPath 'C:\Temp\ctug_review_sandbox_checks' -Recurse -Force
```

## 6. Results table (user fills in; no results recorded here)

| Case | Expected result | Actual result | Status |
|---|---|---|---|
| CSRF bootstrap | HTTP 200; JSON token and CSRF cookie |  | Not run |
| Admin login and cookie rotation | HTTP 200; authenticated; session value changes |  | Not run |
| Cookie persistence / session check | Same jar restores authenticated session |  | Not run |
| Logout | HTTP 200; authenticated false; next check unauthenticated |  | Not run |
| Approved active Student login | HTTP 200; authenticated true |  | Not run |
| Invalid credentials | HTTP 401; `invalid_credentials` |  | Not run |
| Seeded Pending account login | HTTP 401; `invalid_credentials` |  | Not run |
| Sign-up success | HTTP 202; pending-review acknowledgement |  | Not run |
| Duplicate sign-up | HTTP 202; same generic acknowledgement; no second account |  | Not run |
| New Pending account login | HTTP 401; `invalid_credentials` |  | Not run |
| Password mismatch | HTTP 400 validation error |  | Not run |
| Invalid requested role | HTTP 400 validation error |  | Not run |
| Extra sign-up field | HTTP 400 validation error |  | Not run |
| School ID too long | HTTP 400; maximum 7 digits |  | Not run |
| School ID contains non-digits | HTTP 400; digits only |  | Not run |
| Missing CSRF on login | HTTP 403; `csrf_failed` |  | Not run |
| Missing CSRF on sign-up | HTTP 403; `csrf_failed` |  | Not run |
| Expired/invalid session cookie | HTTP 200; authenticated false |  | Not run |
| Role revocation in sandbox DB | Existing session returns authenticated false |  | Not run |
| Account deactivation in sandbox DB | Existing session returns authenticated false |  | Not run |
| Server-down case | Curl connection failure; no auth success |  | Not run |
| adb reverse browser retest | Browser reaches loopback API via reverse; path only |  | Not run |
| Android app cleartext behavior | Unverified; approval needed for any config change |  | Not run |
| Malformed-response behavior | Covered by Flutter mocked tests, not this spike |  | Not run |

## Final reminder

This runbook is preparation only. Addendum approval, sandbox execution approval, Android configuration approval (if needed), and any implementation approval are separate gates. No test result should be entered unless the user reports the actual result.
