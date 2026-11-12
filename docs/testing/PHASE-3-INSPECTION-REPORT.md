# Phase 3 Inspection and Reconciliation Report

> **Phase 3 · Date:** 2026-11-12  
> **Status:** Inspection documented; documentation-only stage authorized and uncommitted  
> **Evidence basis:** Read-only source/repository inspection plus cited Phase 1/2 records  
> **Proposed items are not implemented.**

## 1. Scope and evidence labels

This report records the Phase 3 source inspection and the later approved
documentation-only stage. The protected backend was not edited, staged,
committed, queried for database state, served, or tested. No HTTP request,
build, package command, or test run was made during the documentation-only
stage.

- **Source inspection:** current source was read.
- **Existing test evidence:** test source or existing Phase 1/2 report only; not rerun.
- **Newly executed read-only check:** Git/file metadata/search command.
- **Not executed:** no runtime verification.
- **Blocked / Unresolved:** approval or environment prerequisite missing.
- **Proposed:** not implemented and not an architectural commitment.

## 2. Repository integrity

### Mobile repository

**Newly executed read-only check before documentation edits:**

```text
git status --porcelain=v1 --untracked-files=all
[empty]
git diff --stat
[empty]
branch: main
HEAD: 13afd454503f38a67124c2abbde8972453bd409f
```

The approved documentation stage created seven new files and appended to two
existing files listed below. No source, test, environment, manifest, package,
or ignore file was changed. Ignored files are not visible in ordinary Git
status.

### Protected backend repository

**Newly executed read-only check before documentation edits:**

```text
status:
 M backend/config/settings.py
diff stat:
 backend/config/settings.py | 2 ++
branch: ronald
HEAD: 32675e5b5efa6b0ef881d92d78250d9889e4858f
SHA-256 of git diff --no-ext-diff --binary:
E0D855ECC3C086B5E4930C361F6B7A76D2BC172109A158DE6C2CBA58886A2771
```

The two added lines are the user-owned
`WORKSPACE_FIRST_ADMIN_BOOTSTRAP_ENABLED` setting, disabled by default.
Phase 3 hash A and B matched exactly; this diff is byte-identical to the
confirmed Phase 2 baseline. The earlier Pass 2 `Out-File -Encoding ASCII`
hash is invalid and is not used as evidence.

## 3. Backend routes and modules

**Source inspection:** `backend/config/urls.py:urlpatterns` includes only
`/api/v1/auth/` (`apps.accounts.urls`) and `/admin/`. The seven existing auth
routes are CSRF bootstrap, registration, login, logout, current session,
forgot-password, and reset-password. Full contracts are in
[Mobile API Specification](../architecture/MOBILE_API_SPECIFICATION.md).

Registration-review and bulk-review route modules exist but are not included
in the root URLconf. Review API code checks both
`WORKSPACE_REGISTRATION_REVIEW_API_ENABLED` and
`WORKSPACE_REGISTRATION_APPROVAL_ENABLED`; current main settings do not turn
these on. No routed service API exists for academic, finance, clearance,
announcements, notifications, reports, support, or group rating.

`backend/config/settings.py:MIDDLEWARE` includes CORS, security, sessions,
common, CSRF, authentication, messages, and clickjacking middleware. The
React/Vite app proxies `/api` and preserves Host/Origin in
`frontend/vite.config.ts`.

With `DEBUG=True`, an unknown route is handled by Django's debug HTML 404.
View-level API handlers normalize exceptions, but failures outside those
handlers may return non-JSON debug responses. Mobile clients must tolerate
HTML/non-JSON errors.

## 4. Authentication, registration, and security findings

### Existing session behavior

`CSRFView.get()` returns a token in JSON and causes middleware to set/update
the CSRF cookie. `WorkspaceSessionAPI.initial()` runs `CSRFCheck` for unsafe
methods. Django's installed source confirms: HTTP requests need a matching
CSRF cookie and submitted token; an Origin, if supplied, must pass origin
validation. For HTTPS, an absent Origin requires a valid secure Referer.

No `SESSION_*`, `CSRF_*`, `SECURE_*`, or `CORS_*` project settings were found
in `backend/config/settings.py`. Django defaults apply, including HttpOnly
session cookie, Lax SameSite, non-Secure session cookie, two-week session
cookie age, non-HttpOnly CSRF cookie, and `SESSION_SAVE_EVERY_REQUEST=False`.
These are framework defaults, not production hardening.

`_workspace_account()` in `backend/apps/accounts/session_auth.py` rechecks
active/approved status, staff/superuser exclusion, and active assigned role.
Loss of eligibility denies session access on the next check; no session-row
deletion on a role/status change was found. Existing test source covers
removed-role denial, revoked approval, and logout, but was not run in this
stage. FR-AUTH-04 is **PARTIALLY IMPLEMENTED**: logout and immediate denial are
present; explicit invalidation and expiry policy remain unresolved.

Login returns a generic 401 `invalid_credentials` for invalid credentials,
pending/rejected/inactive users, framework operators, and users without an
active role. A mobile client cannot distinguish pending approval from a wrong
password; this aligns with SRS FR-REG-03 anti-enumeration intent.

### Registration and password recovery

`RegistrationSerializer` accepts Student/Instructor only. `register_account()`
creates a Pending/inactive account and user profile atomically with no role
assignment. Valid duplicate School IDs receive the same public acknowledgement.
Email verification is not part of this registration flow. Review APIs are
inactive/unrouted; the console bootstrap is for the initial Workspace Admin,
not public applicant approval.

Password reset code is present but `WORKSPACE_PASSWORD_RESET_ENABLED` defaults
off. SMTP defaults off. `PASSWORD_RESET_TIMEOUT` is 1800 seconds, and the link
targets the web frontend URL in `WORKSPACE_PUBLIC_BASE_URL` (default
`http://localhost:5173`). Tokens use Django's generator; password change
invalidates the token. This is **implemented in code**, **not enabled by
default**, and **not established as mobile-usable**.

### Rate limiting

Login: 8/min and 40/hour; registration: 5/min and 30/day; recovery:
4/min and 20/day. Keys use `REMOTE_ADDR`. There is no `CACHES` setting, so
Django's local-memory cache is the default and throttles are not shared across
worker processes. No runtime throttle test was run.

### Session-vs-JWT proposal

**PROPOSED:** reuse existing session+CSRF for a development spike with a
persistent cookie jar and `X-CSRFToken`, conditional on approval of mobile
scope in the SRS and a separately approved isolated spike. SimpleJWT is listed
in requirements but is not configured or used. This proposal is **not an
architectural commitment**. No new endpoint is proposed.

The spike is **NOT DESIGNED / NOT APPROVED**. The project runner creates
throwaway MySQL databases during test runs; a live server using a separate
test database and a scripted test identity have not been designed. Creating
accounts is a write and requires separate approval.

## 5. Android, Flutter, and networking

**Source inspection:** main/release [AndroidManifest.xml](../../android/app/src/main/AndroidManifest.xml)
does not declare `android.permission.INTERNET`; debug and profile manifests do.
No `usesCleartextTraffic` or `networkSecurityConfig` configuration was found.
This is a verified release-network-permission gap; no manifest change was
made.

The Flutter code has Riverpod configuration and a single GoRouter startup
route. It has no API client/auth repository/secure cookie store. `AppConfig`
reads `APP_ENV`, `API_BASE_URL`, and `LOG_LEVEL` using `dart-define`.
All five tracked environment examples use those key names; `env/dev.json` was
not opened. The three current Dart test files contain 18 test declarations,
matching the 18 passed reported in the existing
[Phase 2 Test Report](PHASE-2-TEST-REPORT.md); tests were not run here.

**Existing test evidence:** Phase 2 T5 reached Django through emulator
`10.0.2.2` and got HTTP 400 DisallowedHost. T6 `adb reverse` failed to produce
a usable status because of a harness parser error; T8 physical-device reverse
was not tested. Therefore `adb reverse` remains **UNVERIFIED**. If direct
`10.0.2.2` or LAN Host access is selected, explicit host configuration would
be required. Dart/Android cleartext behavior remains **UNVERIFIED**.

## 6. SRS governance blocker and user types

**Source inspection:** SRS §1.2 line 37 places a future Flutter app outside
the current release baseline unless later approved. SRS §2.2 line 73 states
Flutter deployment is not authorized by the current SRS. This blocks mobile
implementation until an addendum/approval; it does not prevent documenting
inspection findings.

SRS user types at line 41 include Students, instructors, SSG Treasurer, SSG
Advisor/Finance Monitor, campus administrators, access-governance
administrators, technical/Django operators, university reviewers/auditors,
and system maintainers. Current login logic can authenticate any approved,
active, non-framework account with an active assigned role. Actual DB
assignments were not checked. Framework staff/superusers are excluded from
Workspace login.

The matrix below classifies current code/API evidence, not the desired SRS
target. Codes such as “PARTIALLY IMPLEMENTED” do not imply a live API.

### Registration and authentication requirements

| Requirement ID | Line | Summary | Existing implementation (`file:symbol`) | API availability | Classification | Mobile relevance |
|---|---:|---|---|---|---|---|
| FR-REG-01 | 173 | Only Student/Instructor public registration; reject privilege fields | `apps.accounts.serializers.RegistrationSerializer`; `views.RegistrationView` | Live register POST | IMPLEMENTED | Registration only if separately approved |
| FR-REG-02 | 174 | Atomic Pending/inactive account + profile; no roles | `apps.accounts.services.register_account`; `AccountManager.create_user` | Live register POST | IMPLEMENTED | Lifecycle prerequisite |
| FR-REG-03 | 175 | Safe password hashing and anti-enumeration | `AccountManager.create_user`; generic registration/login responses | Live register/login | IMPLEMENTED | Login/status UX |
| FR-REG-04 | 176 | Authorized admin review; no self-review | `registration_review_api.require_actor`; `registration_review._decide` | Not included in root URLconf; gates off | PARTIALLY IMPLEMENTED | No mobile review API |
| FR-REG-05 | 177 | Atomic approval, activation and base role | `registration_review.approve_registration` | Review code inactive/unrouted | PARTIALLY IMPLEMENTED | Approved-account lifecycle |
| FR-REG-06 | 178 | Active role defaults evaluated centrally | `access_control.services.get_effective_permissions` | Evaluator exists; no module API | PARTIALLY IMPLEMENTED | UI hints only |
| FR-REG-07 | 179 | Rejected accounts remain unauthorized; retain reviewer attribution | `registration_review.reject_registration` | Review code inactive/unrouted | PARTIALLY IMPLEMENTED | Account state |
| FR-REG-08 | 180 | Restricted operators use authorized provisioning | `accounts.admin_bootstrap.provision_first_workspace_admin`; management command | Console command, not public API | PARTIALLY IMPLEMENTED | Not public registration |
| FR-AUTH-01 | 186 | Web sessions, HttpOnly cookie, CSRF/trusted origin | `WorkspaceSessionAPI.initial`; `LoginView` | Live browser auth routes | PARTIALLY IMPLEMENTED | Production cookie settings not configured |
| FR-AUTH-02 | 187 | Validate password and account eligibility | `LoginView.post`; `_workspace_account` | Live login | IMPLEMENTED | Login |
| FR-AUTH-03 | 188 | Pending/rejected/inactive accounts denied | `_workspace_account` | Live login/session | IMPLEMENTED | Login/session |
| FR-AUTH-04 | 189 | Logout, expiry and critical-change revocation explicitly defined/tested | `LogoutView.post`; `_workspace_account` | Live logout/session | PARTIALLY IMPLEMENTED | Immediate denial; no session row deletion/policy |
| FR-AUTH-05 | 190 | Backend effective permissions and row-scope checks | `access_control.services.has_permission`; no module APIs | No protected service routes | PARTIALLY IMPLEMENTED | Required before service features |
| FR-AUTH-06 | 191 | Current user/permissions without secrets | `SessionView.get`; `_account_payload` | Live GET session | IMPLEMENTED | Session state |
| FR-AUTH-07 | 192 | Rate-limit and log auth events under approved contract | Login throttles exist; no auth-event contract found | Login route throttled; logging requirement incomplete | PARTIALLY IMPLEMENTED | Auth protection |

### Access control and administration requirements

| Requirement ID | Line | Summary | Existing implementation (`file:symbol`) | API availability | Classification | Mobile relevance |
|---|---:|---|---|---|---|---|
| FR-ACL-01 | 198 | Union of active role grants/direct grants; Deny precedence | `access_control.services._authorized_permissions` | Evaluator not a mobile service API | PARTIALLY IMPLEMENTED | Server authority |
| FR-ACL-02 | 199 | Multiple assigned roles and contribution removal | `AccountRole`; access-control mutation services | No role-management API | PARTIALLY IMPLEMENTED | Multi-role display |
| FR-ACL-03 | 200 | Central role defaults affect future evaluation | `RolePermission`; permission evaluator | No role-template API | PARTIALLY IMPLEMENTED | UI hints |
| FR-ACL-04 | 201 | Protected authority for role-default grants | `access_control.mutations`; `delegation` | No live mobile API | PARTIALLY IMPLEMENTED | Admin-only |
| FR-ACL-05 | 202 | Preview role impact before template change | No mobile workflow found | No route | NOT IMPLEMENTED | Admin-only |
| FR-ACL-06 | 203 | Atomic mutations and audit rollback | Access-control mutation/audit services | No mobile route | PARTIALLY IMPLEMENTED | Admin-only |
| FR-ACL-07 | 204 | Explicit service/permission/recipient allowlist | `access_control.delegation.approved_scope` | No mobile route | PARTIALLY IMPLEMENTED | Admin-only |
| FR-ACL-08 | 205 | Separate protected governance workflow | `delegation` safeguards; bootstrap service | No mobile route | PARTIALLY IMPLEMENTED | Admin-only |
| FR-ACL-09 | 206 | Prevent self-approval/grants and unsafe role edits | Mutation/review services contain actor/target checks | No live review route | PARTIALLY IMPLEMENTED | Admin-only |
| FR-ACL-10 | 207 | Detect conflicting simultaneous duties | No complete live policy/API verified | No route | NOT VERIFIED | Mixed-role safety |
| FR-ACL-11 | 208 | Every object API enforces ownership/assignment/period scope | No live object-level service API | No route | NOT IMPLEMENTED | Essential for personal data |
| FR-ACL-12 | 209 | Permission-aware inspection dashboard and audit history | Web dashboard shell exists; no mobile view/API | No mobile route | PARTIALLY IMPLEMENTED | Admin-only |
| FR-ACL-13 | 210 | Planning catalogue remains non-authoritative pending review | Catalogue marks itself planning-only | Static artifact only | IMPLEMENTED | Prevents treating hints as grants |
| FR-ACL-14 | 211 | Express supported composite role profiles | `AccountRole` permits multiple roles; policies/provisioning are incomplete | No mobile role API | PARTIALLY IMPLEMENTED | Role display only |
| FR-ADM-01 | 217 | Assign/revoke ordinary approved roles safely | Access-control mutation services | No active assignment API | PARTIALLY IMPLEMENTED | Admin-only |
| FR-ADM-02 | 218 | Establish additional Normal Admins securely | First-admin bootstrap exists; additional workflow not verified | Console bootstrap only | PARTIALLY IMPLEMENTED | Admin-only |
| FR-ADM-03 | 219 | Ordinary Admin cannot grant Super Admin | Governance/delegation controls exist; end-to-end route absent | No live API | PARTIALLY IMPLEMENTED | Admin-only |
| FR-ADM-04 | 220 | Protected Super Admin promotion/removal/recovery | Bootstrap/delegation mechanisms exist; complete workflow not verified | No live API | PARTIALLY IMPLEMENTED | Admin-only |
| FR-ADM-05 | 221 | Audit role changes with actor/target/reason/time | `AccessAuditLog`; mutation/audit services | No mobile audit API | PARTIALLY IMPLEMENTED | Admin-only |
| FR-ADM-06 | 222 | Scoped inspection of roles/effective abilities | Evaluator exists; no inspection route | No API | NOT IMPLEMENTED | Admin-only |
| FR-ADM-07 | 223 | Redacted school-scoped auth log | No authentication-event source/view verified | No API | NOT IMPLEMENTED | Admin/security |
| FR-ADM-08 | 224 | Prevent Treasurer self-interest actions | Finance app has placeholder models/views | No API | NOT IMPLEMENTED | Treasurer/student |
| FR-ADM-09 | 225 | Explicit SSG Advisor eligibility/duration/read-only grants | No live appointment/service API | No API | NOT IMPLEMENTED | Advisor |

### Academic, finance, clearance and group requirements

| Requirement ID | Line | Summary | Existing implementation (`file:symbol`) | API availability | Classification | Mobile relevance |
|---|---:|---|---|---|---|---|
| FR-ACA-01 | 231 | Maintain academic definitions/profiles | `apps.academic.models`/`views` placeholders | No route | NOT IMPLEMENTED | School admin |
| FR-ACA-02 | 232 | Instructor sees assigned students/teaching only | No academic models/service | No route | NOT IMPLEMENTED | Instructor |
| FR-ACA-03 | 233 | Student sees own profile/catalogue | No academic models/service | No route | NOT IMPLEMENTED | Student |
| FR-ACA-04 | 234 | Preserve historical academic consistency | No academic model/service | No route | NOT IMPLEMENTED | Admin/student |
| FR-FIN-01 | 240 | Treasurer manages fees/payments/receipts/funds/expenses | `apps.finance.models`/`views` placeholders | No route | NOT IMPLEMENTED | Treasurer |
| FR-FIN-02 | 241 | Student views own permitted payments/receipts | No finance model/service | No route | NOT IMPLEMENTED | Student |
| FR-FIN-03 | 242 | Advisor gets three scoped read-only finance abilities | No finance model/service | No route | NOT IMPLEMENTED | Advisor |
| FR-FIN-04 | 243 | Advisor cannot write or manage roles | No finance service to enforce | No route | NOT IMPLEMENTED | Advisor |
| FR-FIN-05 | 244 | Transaction-history scope/redaction/export limits | No finance service to enforce | No route | NOT IMPLEMENTED | Advisor |
| FR-FIN-06 | 245 | Prevent Treasurer acting on own obligations | No finance service to enforce | No route | NOT IMPLEMENTED | Student/Treasurer |
| FR-FIN-07 | 246 | Advisor and Finance Monitor are one responsibility | Role model can represent a role; appointment policy/API absent | No route | PARTIALLY IMPLEMENTED | Advisor |
| FR-FIN-08 | 247 | Validate report source/period and finalization controls | No finance/report service | No route | NOT IMPLEMENTED | Treasurer/admin |
| FR-CLR-01 | 253 | Student submits/tracks eligible clearance | `apps.clearance.models`/`views` placeholders | No route | NOT IMPLEMENTED | Student |
| FR-CLR-02 | 254 | Signatory signs only assigned requests | No clearance service | No route | NOT IMPLEMENTED | Instructor/signatory |
| FR-CLR-03 | 255 | Admin manages assignments/signatories safely | No clearance service | No route | NOT IMPLEMENTED | Admin |
| FR-CLR-04 | 256 | Scope signature reuse and protect raw signature | No clearance service | No route | NOT IMPLEMENTED | Student/signatory |
| FR-CLR-05 | 257 | Keep messages unavailable pending privacy semantics | No clearance messaging API | No route | NOT IMPLEMENTED | Student |
| FR-RAT-01 | 263 | Instructor ratings limited to assigned class/period | `apps.group_rating` placeholders | No route | NOT IMPLEMENTED | Instructor |
| FR-RAT-02 | 264 | Student responds to own verified invitation | No group-rating service | No route | NOT IMPLEMENTED | Student |
| FR-RAT-03 | 265 | Prevent invalid, self, duplicate ratings | No group-rating service | No route | NOT IMPLEMENTED | Student/instructor |
| FR-RAT-04 | 266 | Scope rating result disclosure | No group-rating service | No route | NOT IMPLEMENTED | Student/instructor |

### Communications, audit, Django admin, and UI

| Requirement ID | Line | Summary | Existing implementation (`file:symbol`) | API availability | Classification | Mobile relevance |
|---|---:|---|---|---|---|---|
| FR-COM-01 | 272 | Authorized admins create/update announcements | Announcement model/view placeholders | No route | NOT IMPLEMENTED | Campus users/admin |
| FR-COM-02 | 273 | Read eligible announcements and own read state | No announcement/read API | No route | NOT IMPLEMENTED | Campus users |
| FR-COM-03 | 274 | Define audience before public exposure | No audience API; SRS identifies gap | No route | NOT IMPLEMENTED | Privacy-critical |
| FR-COM-04 | 275 | Distinguish report detail/export levels | No live report API | No route | NOT IMPLEMENTED | Treasurer/admin |
| FR-AUD-01 | 281 | Audit role/template/override changes atomically | Access audit and mutation services | No audit mobile API | PARTIALLY IMPLEMENTED | Admin/security |
| FR-AUD-02 | 282 | Separate secure auth-event source/retention | No auth-event implementation verified | No route | NOT IMPLEMENTED | Admin/security |
| FR-AUD-03 | 283 | Redacted, school-scoped auth-log view | No auth-event log view | No route | NOT IMPLEMENTED | Admin/security |
| FR-AUD-04 | 284 | Scoped governance/security event inspection | Access audit model exists; no complete viewer API | No route | PARTIALLY IMPLEMENTED | Governance |
| FR-AUD-05 | 285 | Avoid secrets and sensitive payloads in audits | Audit code contains bounded/redaction safeguards; no mobile audit API | No route | PARTIALLY IMPLEMENTED | Security |
| FR-DJA-01 | 286 | Reviewed Django Superuser provisioning | `AccountManager.create_superuser`; bootstrap management command | Console/Framework Admin, not mobile | PARTIALLY IMPLEMENTED | Technical operator |
| FR-DJA-02 | 287 | Separate framework privilege from app roles | `Account` flags; `_workspace_account` excludes framework admins | Login route enforces separation | IMPLEMENTED | Admin separation |
| FR-DJA-03 | 288 | Document compatibility gap before adapting model | Account flags/methods and migrations present; no new adaptation in this phase | Not a mobile API | PARTIALLY IMPLEMENTED | Technical operator |
| FR-DJA-04 | 289 | Restrict Django Admin maintenance functions | `accounts.admin`; `access_control.admin` | `/admin/` only | PARTIALLY IMPLEMENTED | Not a mobile feature |
| FR-DJA-05 | 290 | Authenticated attributable superuser procedure | `bootstrap_workspace_admin.Command`; `provision_first_workspace_admin` | Local console, gated | PARTIALLY IMPLEMENTED | Technical operator |
| FR-DJA-06 | 291 | Do not conflate framework Superuser with first app Admin | `provision_first_workspace_admin` uses operator separate from new Admin | Local console | IMPLEMENTED in code | Admin separation |
| FR-DJA-07 | 292 | Separate technical actions and app authority | Separate models/flags and bootstrap audit action exist; complete ops policy not verified | No mobile route | PARTIALLY IMPLEMENTED | Technical operator |
| FR-UI-01 | 298 | Shared permission-aware DashboardLayout | Web dashboard shell/nav exists; mobile app only startup shell | Web only | PARTIALLY IMPLEMENTED | Current mobile scope excludes UI |
| FR-UI-02 | 299 | Normal Admin screens | Web shell/planned navigation; no live module APIs | No mobile route | NOT IMPLEMENTED | Admin |
| FR-UI-03 | 300 | Super Admin governance screens | No complete mobile governance UI/API | No mobile route | NOT IMPLEMENTED | Admin |
| FR-UI-04 | 301 | One account/session for multiple roles | Backend role model and session payload support multiple roles | Live session route | PARTIALLY IMPLEMENTED | Relevant if mobile approved |
| FR-UI-05 | 302 | Distinguish global role-default vs per-user permission edits | No mobile role editor | No route | NOT IMPLEMENTED | Admin |
| FR-UI-06 | 303 | Confirmation/error UX never substitutes for server enforcement | Web shell exists; no mobile privileged UI/API | No mobile route | NOT IMPLEMENTED | Admin |

### Nonfunctional requirements

| Requirement ID | Line | Summary | Existing implementation (`file:symbol`) | API availability | Classification | Mobile relevance |
|---|---:|---|---|---|---|---|
| NFR-SEC-01 | 338 | Deny-by-default permission and row-scope testing | Permission evaluator exists; no service routes/row-scope API | No service API | PARTIALLY IMPLEMENTED | Required before data access |
| NFR-SEC-02 | 339 | HTTPS, secure cookies, CSRF, throttles, safe hashes | CSRF/throttles/password hashing exist; Secure cookie/production config absent | Browser auth only | PARTIALLY IMPLEMENTED | Mobile and deployment |
| NFR-SEC-03 | 340 | Prevent escalation and Superuser bypass | Role restrictions and framework exclusion exist; live API scope limited | Limited auth routes | PARTIALLY IMPLEMENTED | Auth/role safety |
| NFR-AUD-01 | 341 | Atomic security mutations and bounded audit | Mutation/audit service code exists | No mobile audit API | PARTIALLY IMPLEMENTED | Security |
| NFR-PRV-01 | 342 | Minimize and scope personal/financial data | No business data API/deployment evidence | No service API | NOT VERIFIED | Privacy applies to mobile |
| NFR-REL-01 | 343 | Fail closed; avoid duplicate idempotent writes | Permission evaluation fails closed; service APIs absent | No service API | PARTIALLY IMPLEMENTED | Reliability |
| NFR-PER-01 | 344 | 95% ordinary reads within proposed 2 seconds under agreed load | No load test/evidence collected | No service API | NOT VERIFIED | Performance |
| NFR-USA-01 | 345 | Aim for WCAG 2.2 AA essential web flows | No mobile accessibility audit in this phase | No mobile UI | NOT VERIFIED | Relevant if mobile authorized |
| NFR-OPS-01 | 346 | Define recovery, retention and incident response | No hosting/operations review in this phase | No API | NOT VERIFIED | Device/service operations |
| NFR-MNT-01 | 347 | Modular services, reusable components, versioned catalogue, tests/docs | Existing modular code and catalogue; mobile auth/service layers absent | Limited | PARTIALLY IMPLEMENTED | Maintainability |
| NFR-TEST-01 | 348 | Test role combinations/escalation with disposable DB suites | Test code and isolated MySQL runner exist; full coverage/result not rerun | Not an API | PARTIALLY IMPLEMENTED | Testing prerequisite |

## 7. Host, runtime, and API limitations

`DEBUG=True` and `ALLOWED_HOSTS=[]` permit localhost/loopback by Django's
development fallback; `10.0.2.2` is rejected. An explicit host-list proposal
is OPTIONAL and depends on the selected development path. `adb reverse` is
unverified; Phase 2 T6 was inconclusive and T8 was not tested. See the
[Phase 2 Test Report](PHASE-2-TEST-REPORT.md) and
[ADR-004](../decisions/ADR-004-DEVELOPMENT-NETWORK-ACCESS.md).

No runtime mobile request or auth spike was executed for Phase 3. No Android
INTERNET permission, cleartext policy, package, or app implementation change
was made.

## 8. Proposed documentation-stage outcomes

Seven new files:

1. `docs/architecture/API_ARCHITECTURE.md`
2. `docs/architecture/AUTHENTICATION_ARCHITECTURE.md`
3. `docs/architecture/ROLE_PERMISSION_MAPPING.md`
4. `docs/architecture/MOBILE_API_SPECIFICATION.md`
5. `docs/architecture/PHASE-3-BACKEND-CHANGE-PROPOSAL.md`
6. `docs/decisions/ADR-005-MOBILE-AUTHENTICATION-STRATEGY.md`
7. `docs/testing/PHASE-3-INSPECTION-REPORT.md`

Two append-only updates:

- `docs/CHANGELOG.md`
- `docs/BACKEND_CHANGE_REGISTER.md`

No Phase 1/2 report, ADR-001–004, SRS, or DBML file was modified.

## 9. Unresolved decisions

All are **UNRESOLVED; owner: Mister2 (project owner)** unless noted otherwise:

- Backend change owner and branch: NOT YET DECIDED; backend currently `ronald`.
- Hosting/domain for real devices, HTTPS: NOT YET DECIDED.
- Approver for SRS addendum authorizing Flutter: NOT YET DECIDED.
- Keep/ignore/disable Java-upgrade Copilot hook folder: NOT YET DECIDED.
  - **Observation, not a conclusion:** `.github/modernize/java-upgrade/` is ignored by its own `.gitignore` (`**/*`), so ordinary `git status` cannot show changes inside it. `recordToolUse.ps1`/`.sh` last-modified times (6:54:56 pm on 12/11/2026) are later than the folder's (1:37:11 pm), which suggests the extension rewrites them during sessions. No action was taken.
- Android release INTERNET permission: NOT APPROVED.
- Dio, cookie jar, secure-storage packages: NOT APPROVED.
- Isolated spike environment and test-account creation: NOT APPROVED.
- Production-style configuration and deployment: unresolved hosting decision.
- Whether any new service API is required: separate future scope/approval.

## 10. Verification performed during documentation stage

**Newly executed read-only checks:** mobile and backend Git baselines; backend
binary diff hash before documentation; file/source reads and cross-reference
searches. The server reachability check from the inspection pass was already
reported as unavailable; no HTTP request was made in this documentation stage.

**Not executed:** backend tests, Flutter tests, builds/analyzers, database
access, server startup, POST/GET requests, spike, package installation,
commits, or pushes.

The final documentation-stage checks and resulting file line counts are
recorded in the chat handoff. This file must be updated only if a verified
documentation defect is found; do not rewrite historical Phase 1/2 evidence.

## Related documents

- [API Architecture](../architecture/API_ARCHITECTURE.md)
- [Authentication Architecture](../architecture/AUTHENTICATION_ARCHITECTURE.md)
- [Role and Permission Mapping](../architecture/ROLE_PERMISSION_MAPPING.md)
- [Mobile API Specification](../architecture/MOBILE_API_SPECIFICATION.md)
- [Backend Change Proposal](../architecture/PHASE-3-BACKEND-CHANGE-PROPOSAL.md)
- [Proposed ADR-005](../decisions/ADR-005-MOBILE-AUTHENTICATION-STRATEGY.md)
