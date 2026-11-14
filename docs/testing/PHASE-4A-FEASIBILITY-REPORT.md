# PHASE 4A — Feasibility report

## Scope

This report records the Turn 1 inspection outcomes for the proposed mobile Sign In / Sign Up work. It is a documentation-only feasibility check. No app dependency, Android manifest change, or backend change was made.

## VERIFIED

- The mobile app is a Flutter/Dart Android app under `C:\Users\Janrey\CTU-G_Workspace Mobile App` with existing Riverpod, GoRouter, and Material 3 setup.
- The app currently has a `AppConfig` environment loader using `APP_ENV`, `API_BASE_URL`, and `LOG_LEVEL` (`lib/core/config/app_config.dart`), and a startup route exists (`lib/app/router.dart`, `lib/app/startup_screen.dart`).
- The codebase does not yet include an HTTP client, auth repository, cookie jar, CSRF handling, or sign-in/sign-up screens. There is no mobile auth implementation in the repo.
- The protected backend route map includes `/api/v1/auth/csrf/`, `/api/v1/auth/register/`, `/api/v1/auth/login/`, `/api/v1/auth/logout/`, and `/api/v1/auth/session/` (`backend/config/urls.py`, `backend/apps/accounts/urls.py`).
- The backend code explicitly enforces CSRF for unsafe methods in `backend/apps/accounts/session_auth.py:WorkspaceSessionAPI.initial()` and `backend/apps/accounts/views.py:RegistrationView.initial()`.
- `LoginView.post()` accepts only `school_id` and `password` in `LoginSerializer`, and the login flow authenticates against Django auth with a server-side session (`backend/apps/accounts/session_auth.py`).
- Public registration accepts only `Student` or `Instructor` via `RegistrationSerializer.requested_role` restrictions, and the backend message says eligible new accounts remain pending admin review (`backend/apps/accounts/views.py`).
- `DEBUG = True` and `ALLOWED_HOSTS = []` are present in `backend/config/settings.py` and therefore the backend is currently a development-only configuration, not a production-ready mobile deployment baseline.
- The SRS states in §1.2 that Flutter deployment is outside the current scope; §2.2 states future Flutter deployment is not authorized by that release baseline (`docs/SRS/CTU-G_Workspace_SRS_v1.md`).
- ADR-005 explicitly labels the mobile session+CSRF path as a proposal, not an architectural commitment, and says the spike is not designed or approved (`docs/decisions/ADR-005-MOBILE-AUTHENTICATION-STRATEGY.md`).
- The Android main manifest currently does not declare `android.permission.INTERNET` (`android/app/src/main/AndroidManifest.xml`); only the debug manifest includes it (`android/app/src/debug/AndroidManifest.xml`).

## UNVERIFIED

- Whether the app can successfully reach the backend on the Android emulator or a physical device using the approved network path.
- Whether a safe isolated backend test environment can be created without affecting the protected backend repo.
- Whether the course approver(s) will sign the mobile SRS addendum and authorize Flutter auth scope.
- Whether a backend change would be required to satisfy any future mobile auth design beyond the existing browser session flow.
- Whether the project owner, backend owner, and instructor will approve a testing identity and review flow.

## ASSUMED

- A production or non-loopback backend is not safe to target without additional approval and configuration because the live repo is currently using development settings and local-only host behavior.
- The required mobile auth path is likely to be the existing Django session + CSRF flow, but this remains unapproved pending the SRS addendum.
- Any future backend write or settings change must be treated as a separate, explicit approval item and not be bundled into mobile app work.

## Conclusion

The codebase is technically ready for a mobile-auth documentation and design phase, but not yet approved for implementation or a live spike. The likely implementation path is session + CSRF reuse, but that path remains a proposal until the mobile SRS addendum is approved. No implementation should proceed under Turn 4 without written approval and a separately approved isolated test environment.
