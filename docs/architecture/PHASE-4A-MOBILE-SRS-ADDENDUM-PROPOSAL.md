# PHASE 4A — Mobile SRS addendum proposal

## Status

**Status:** APPROVED by project owner on 2026-11-14

## To

Project owner: Janrey Ferrer  
Additional reviewer: Glicerio Baguia (approval: given on 2026-11-14)  
Approval evidence: signed line in this addendum and a dated message from the instructor saved in the project docs

## Purpose

This addendum requests explicit approval to include Flutter deployment and mobile authentication in the Phase 4 scope. The proposal does not request browser JWT storage or backend changes; it only seeks a scoped approval for a mobile session-based sign-in/sign-up flow using the current Django auth contract.

## Current evidence summary

- The SRS says Flutter deployment and autonomous AI permissions are outside the approved baseline and specifically notes that browser JWT storage is not authorized (`docs/SRS/CTU-G_Workspace_SRS_v1.md`, §1.2 and §2.2).
- ADR-005 records that the mobile session+CSRF approach is proposed but not approved.
- The current backend contract is Django server-session authentication with CSRF protections and no configured SimpleJWT flow.

## Proposed scope

### In scope

- Flutter Android app sign-in using the existing Django session model.
- Flutter Android app sign-up for eligible `Student` or `Instructor` requests.
- Session restoration and logout using the existing backend routes.
- Secure cookie handling, `X-CSRFToken` use, and validation of server responses.
- Minimal authenticated landing screen for the mobile app only.

### Out of scope

- Browser JWT storage.
- Any request to remove CSRF protections or weaken origin checks.
- Backend changes to Django settings or auth architecture without a separate proposal and approval.
- Database creation or production data access for testing without explicit approval.
- Role dashboards or business features beyond the minimal authenticated landing screen.

## Security and implementation constraints

- Keep the current server-side browser session contract and do not introduce JWT storage for mobile without separate approval.
- Reuse Django session and CSRF flow only if the SRS addendum approves it.
- Do not disable CSRF, do not broaden trusted origins, and do not store sensitive credentials in plain local storage.
- Treat backend changes (including any `ALLOWED_HOSTS` or security setting update) as a separate request, not as part of the Phase 4 mobile app scope.

## Proposed approval language

The undersigned approve the following Phase 4A mobile addendum if this proposal is accepted:

- Flutter mobile deployment is approved as a project scope extension for a limited authentication flow only.
- The mobile implementation may reuse the current Django session + CSRF contract as a proposed design path; this remains subject to the approved isolated test plan.
- Browser JWT storage is explicitly not requested and remains outside this approval.
- Backend changes, if required later, remain separate requests and do not begin without a documented proposal approved by the project owner.

## Signatures

- Project owner: Janrey Ferrer, 2026-11-14, approved by instruction in chat
- Course instructor / reviewer: _________________________________
- Date: __________________________________________

## Note

ADR-005 remains the proposal for session + CSRF reuse, and this addendum merely requests the explicit approval required to continue with Phase 4A documentation and implementation planning.
