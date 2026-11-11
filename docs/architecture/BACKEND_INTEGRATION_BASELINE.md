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
