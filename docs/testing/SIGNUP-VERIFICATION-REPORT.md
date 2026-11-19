# Sign-up and Email Verification Report

Report date: 2026-11-20

## Scope

**VERIFIED:** This report documents the mobile sign-up and email-verification
changes from commits `7eb70d9`, `e3b9163`, and `1f08dd4`. It is based on the
mobile source, tests, Git history, and read-only backend source inspection.
No backend code or configuration was run.

## Changes

- **VERIFIED — `7eb70d9`, 2026-11-19:** Added the display-only
  `03 — School Information` section for Student registration. It is hidden for
  Instructor, appears after Personal Information and before the submit button,
  and adds no form inputs or request fields. Tests cover role switching,
  vertical order, unchanged field counts, request keys, and no overflow at
  360×640 with text scale 1.5.
- **VERIFIED — `e3b9163`, 2026-11-19:** Changed the sign-up button label from
  `Create account` to `Proceed Email Verification`. The “Already registered?”
  / “Sign In” row was unchanged. The 1.5 text-scale test passes.
- **REPORTED:** A focused text-scale 2.0 test reported a password-field
  `InputDecorator` overflow, including with the old button label. The current
  full test suite does not test scale 2.0.
- **VERIFIED — `1f08dd4`, 2026-11-19:** Added a private response parser that
  checks the exact HTTP status and allowed body status for registration,
  status, verification, and resend. Cancellation remains HTTP 200 with
  `cancelled`. The status mock that previously used the default HTTP 200 was
  changed to 202. Tests now cover both status states, reject the wrong HTTP
  status and an unexpected body state, cover resend success at 202, and retain
  the resend cooldown error check.

## Contract table

**VERIFIED:** The backend response adapter in
`backend/apps/accounts/student_registration_api.py` returns 202 for
`verification_required` and `existing_verification`, and 200 for `completed`
and `cancelled`. The mobile client enforces these success statuses and
endpoint-specific body states.

| Endpoint | Method | Backend success status and state | Mobile accepts |
|---|---|---|---|
| `/api/v1/auth/register/` | POST | 202 — `verification_required` or `existing_verification` | 202 — either state |
| `/api/v1/auth/register/verification/` | GET | 202 — `verification_required` | 202 — `verification_required` or `existing_verification` |
| `/api/v1/auth/register/verify/` | POST | 200 — `completed` | 200 — `completed` |
| `/api/v1/auth/register/resend/` | POST | 202 — `verification_required` | 202 — `verification_required` |
| `/api/v1/auth/register/cancel/` | POST | 200 — `cancelled` | 200 — `cancelled` |

The status service currently produces `verification_required` for a live
staging record. The response adapter maps `existing_verification` to 202 as
well; the mobile status method accepts both states.

**VERIFIED:** Error responses remain errors, not successful verification
states: `otp_invalid`, `otp_expired`, and `attempts_exhausted` use HTTP 400;
`conflict` uses 409; `expired` uses 410; `resend_cooldown` and
`resends_exhausted` use 429; `delivery_failed` and `registration_unavailable`
use 503. Request validation uses 400, CSRF failure 403, and throttling 429.
The mobile transport continues mapping these responses through its existing
error handling.

## Findings

- **REPORTED:** Runtime observation: `POST /api/v1/auth/register/` returned
  HTTP 202, followed by `GET /api/v1/auth/register/verification/` returning
  HTTP 202. The screen then showed “We could not confirm your registration
  status” and no code field. The earlier client expected HTTP 200.
- **REPORTED:** A successful `POST /api/v1/auth/register/resend/` returning
  HTTP 202 was not observed at runtime. The only resend response observed was
  HTTP 503 `delivery_failed`. **VERIFIED:** Backend source specifies HTTP 202
  for successful resend. Earlier test coverage used the status mock’s default
  HTTP 200 and had no resend-success test.
- **VERIFIED:** The client and tests now match the backend’s success-status
  contract. Lesson from the reported failure: compare HTTP status handling and
  test mocks with server responses, not only response bodies.
- **VERIFIED:** The sign-up screen locally checks password presence and length
  from 8 through 128 characters. It does not show a dedicated password
  requirements hint. The backend serializer calls Django password validation
  with a candidate containing the School ID as username, email, first name,
  and last name; backend settings include similarity, minimum-length,
  common-password, and numeric-password validators. The mobile
  forgot-password screen and web registration page show a password hint. No
  password UI change was made.
- **REPORTED:** The owner reported `delivery_failed` (HTTP 503) for registration
  and resend and a Django shell SMTP rejection saying
  `550 5.4.5 Daily user sending limit exceeded` from the project's Gmail sender
  account. This SMTP result was not independently reproduced.
- **VERIFIED:** Backend settings select Django’s console email backend when
  `WORKSPACE_EMAIL_SMTP_ENABLED` is not `1`, and SMTP when it is `1`.
  **REPORTED:** The console email backend was suggested as a development
  workaround; its use was not confirmed. The mobile commits did not change
  backend configuration.
- **REPORTED:** Gmail returned a daily sending-limit error for the project's
  Gmail sender account. The reset timing for this account is **UNVERIFIED**
  (secondary sources describe a rolling window of up to about 24 hours).
  Google's Gmail Help page says that after the web message 'You have reached a
  limit for sending mail', sending may resume within 1 to 24 hours. That page
  does not mention SMTP error 550 5.4.5 specifically, and it points work or
  school accounts to a different page (support.google.com/a/answer/166852), so
  the exact timing for this project's sender account is **UNVERIFIED**.
  [Gmail Help](https://support.google.com/mail/answer/22839?hl=en)

## Verified / Reported / Unverified

| Status | Item | Evidence |
|---|---|---|
| VERIFIED | Commit hashes, dates, and changed files for the three changes | Mobile `git log` and `git show --stat` |
| VERIFIED | Role-gated display note, button label, nine-field request, and API status checks | Mobile implementation and widget/API client tests |
| VERIFIED | `flutter analyze --no-pub`: `No issues found! (ran in 38.2s)` | Run during this documentation review |
| VERIFIED | `flutter test --no-pub`: `00:20 +116: All tests passed!` | Run during this documentation review |
| REPORTED | Runtime registration response 202, status response 202, and resend `delivery_failed` response 503 | Owner’s development-backend observation |
| REPORTED | Text-scale 2.0 password-field overflow, including with the old button label | Focused test result from the implementation session; current full suite does not cover 2.0 |
| REPORTED | Gmail daily sending-limit SMTP error | Owner’s Django shell observation |
| UNVERIFIED | Complete real-backend flow with an actually delivered email | No complete end-to-end run was confirmed |
| UNVERIFIED | Real-phone appearance and Instructor flow | Not verified end to end |
| UNVERIFIED | Reset timing for this project’s Gmail sender account | Not independently confirmed |

## Open items

- **VERIFIED:** The verification screen renders “Verify your email” in both its shared header and a second heading.
- **VERIFIED:** When status restoration fails and no state is loaded, the screen can also show the “could not send a code” message.
- **REPORTED / UNVERIFIED visually:** Resend and Cancel text buttons have low contrast on the dark background.
- **VERIFIED:** The registration response is used to select the role/resumed state, then the verification screen fetches status again instead of using the full returned status payload.
- **VERIFIED in code; UNVERIFIED at runtime:** Cancelling returns to a default `SignUpScreen`, whose selected role is Student; the Instructor cancellation flow was not completed end to end.
- **REPORTED:** A focused test reported text scale 2.0 overflow in the password field’s `InputDecorator`; the current full test suite does not test scale 2.0.
- **VERIFIED:** Web/app wording differs: the web registration page says “Back to Home” while the app sign-up row says “Already registered? Sign In”; the web loading label is “Requesting verification…” while the app shows a spinner.

## How to re-test manually

This is a procedure, not evidence that these steps have been completed.

1. Start the mobile app against the development backend and register as Student.
2. Confirm the verification screen restores status and shows the code input when delivery succeeded.
3. Enter an incorrect six-digit code and confirm the fixed error message and remaining-attempt count.
4. Enter the correct code from the delivered email, then confirm the pending-review state appears without signing in.
5. Wait for the configured resend cooldown, request a resend, and confirm a new code arrives.
6. Cancel the staged registration and confirm the app returns to sign-up.
7. Repeat with Instructor selected.
8. If SMTP delivery is unavailable, the console email backend is a suggested development workaround; its use has not been confirmed. A console-delivered message does not verify real SMTP delivery.
