# Backend Integration Baseline

All facts in the first section are from the supplied snapshot zip of
`CTU-G_Workspace` reviewed 2026-11-11. They were not re-verified against the
live protected repository during Phase 1. No backend files were read or changed
for this implementation.

## Verified facts (snapshot)

- `backend/requirements.txt` listed Django 6.1.2, Django REST Framework 3.18.3,
  `djangorestframework_simplejwt` 5.5.1, PyJWT 2.15.1,
  `django-cors-headers` 4.9.0, `mysqlclient` 2.3.0, and psycopg.
- Frontend `package.json` listed React `^19.3.1`, TypeScript `~6.0.3`, and
  Vite `^8.3.4`.
- Settings used the MySQL engine with the database name from environment
  configuration. `DEBUG = True`, `ALLOWED_HOSTS = []`, and CORS middleware
  were present. No `CORS_*`, `REST_FRAMEWORK`, or `SIMPLE_JWT` settings were
  found in the reviewed snapshot. `rest_framework_simplejwt` was not in
  `INSTALLED_APPS`; CSRF middleware was active.
- Routed endpoints were under `/api/v1/auth/`: CSRF, register, login, logout,
  session, forgot-password, and reset-password.
- No other app routes were present in the snapshot. The academic, finance,
  clearance, group-rating, announcements, and notifications apps had stub
  empty models. A registration-review API existed but was not routed; dashboard
  item AR-6D was pending.
- `docs/DEVELOPMENT_STATUS.md` (as of 2026-11-08) named database
  `ctug_workspace`; `AUTH_ENDPOINT_INVENTORY.md` was marked draft.

## Assumptions / constraints

- The mobile client will use a future backend API boundary and will not connect
  directly to MySQL (project requirement).
- Django remains authoritative for backend data and decisions; client-side
  state is not authoritative (project requirement).
- The snapshot is reference context only; any implementation decision must
  verify the live backend separately with authorization.
- No endpoint behavior, token contract, permission rule, or deployment setting
  is inferred by this Phase 1 mobile foundation.

## Open questions

1. What are the effective DRF default authentication classes? They were not
   verified in the snapshot.
2. What MySQL server version is deployed?
3. What account activation and registration approval rules apply?
4. How are effective permissions calculated?
5. What role/override rules should apply to a mobile client?
6. What `ALLOWED_HOSTS` entries will be required for LAN access?
7. Is CORS needed at all for a native client? No decision is assumed.
8. What HTTPS certificate strategy will work on physical devices?
9. Which existing or future endpoints are reusable for mobile, and what are
   their request/response contracts?

## Phase 2 live audit — 2026-11-12

The following is a read-only audit of the live protected repository,
`CTU-G_Workspace`. The original snapshot section above remains historical and
was not rewritten. Backend files were not modified by the assistant.

| Finding | Live observation and evidence |
|---|---|
| Dependency versions | `backend/requirements.txt:2-5`: Django 6.1.2, django-cors-headers 4.9.0, Django REST Framework 3.18.3, djangorestframework_simplejwt 5.5.1. These match the snapshot versions; the earlier audit transcription of DRF was corrected. |
| Settings module | `backend/manage.py:9`: `DJANGO_SETTINGS_MODULE` defaults to `config.settings`. |
| Debug and host validation | `backend/config/settings.py:37-39`: `DEBUG = True`, `ALLOWED_HOSTS = []`; confirmed against snapshot. Django 6.1 documents localhost/loopback fallback for DEBUG with an empty list. |
| CORS | `backend/config/settings.py:55-56,74`: corsheaders app and middleware are present; no explicit `CORS_*` settings were found in the main settings file. |
| CSRF | `backend/config/settings.py:78` enables `CsrfViewMiddleware`; `backend/apps/accounts/session_auth.py:55-64` performs explicit CSRF checking for unsafe session API methods. No explicit `CSRF_*` settings were found in main settings. |
| DRF defaults and overrides | No `REST_FRAMEWORK` setting was found in `backend/config/settings.py`. The session API explicitly sets `authentication_classes = []` and `permission_classes = [AllowAny]` at `backend/apps/accounts/session_auth.py:48-52`. |
| Session/cookie and TLS settings | No explicit session/CSRF cookie hardening, `SECURE_SSL_REDIRECT`, `SECURE_PROXY_SSL_HEADER`, HSTS, or `USE_X_FORWARDED_HOST` settings were found in the main settings file. Framework defaults therefore apply unless deployment configuration supplies other behavior. |
| Database | `backend/config/settings.py:105-112`: MySQL engine; connection values come from `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_HOST`, and `DB_PORT` environment variables. Values were not read or recorded. |
| Routed API methods | `backend/config/urls.py:21` includes `apps.accounts.urls` at `api/v1/auth/`. `backend/apps/accounts/urls.py:9-15` routes: `csrf/` GET/HEAD/OPTIONS (`views.py:97-100`); `register/` POST/OPTIONS (`views.py:102-104`); `login/` POST/OPTIONS (`session_auth.py:130-132`); `logout/` POST/OPTIONS (`session_auth.py:164-166`); `session/` GET/HEAD/OPTIONS (`session_auth.py:174-177`); `forgot-password/` POST/OPTIONS (`password_reset.py:64-66`); `reset-password/` POST/OPTIONS (`password_reset.py:103-105`). |
| Safe connectivity route | `/api/v1/auth/session/`, `GET`: `SessionView` uses `AllowAny` and reads the session; it does not write to the database or send email (`session_auth.py:48-52,174-182`). It can perform reads for an authenticated session. |
| Development bind/port | The user reported their usual run command uses loopback port 8000 with Python 3.13.7, Django 6.1.2, DRF 3.18.3, and no virtual environment. The repository did not establish a separate supported network bind/port contract. |

The workstation audit found a Public active Wi-Fi profile. Stage B LAN access
was deferred; no firewall change or backend proposal was implemented.
Connectivity outcomes, including the T6 limitation and the accidental second
server report, are in the [Phase 2 Test Report](../testing/PHASE-2-TEST-REPORT.md).
