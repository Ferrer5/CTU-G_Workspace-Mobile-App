# CTU-G Workspace Role and Permission Mapping

> **Phase 3 · Date:** 2026-11-12  
> **Status:** Verified source inventory; service policies and mobile scope remain unresolved  
> **Evidence basis:** Read-only model/service/SRS inspection  
> **Proposed items are not implemented.**

## Account and role representation

**Source inspection:** `apps.accounts.models.Account` is the custom user model.
It stores `school_id`, optional email, `requested_role`, `request_status`,
`is_active`, `is_staff`, and `is_superuser`. Registration requests Student or
Instructor and creates Pending/inactive accounts. Requested role is not an
assignment.

`apps.access_control.models` defines `Role`, `AccountRole`, `Service`,
`Permission`, `RolePermission`, `AccountPermission`, and `AccessAuditLog`.
`AccountRole` has a unique `(account, role)` constraint and assigned-by
attribution. Direct account overrides are `Grant` or `Deny`.

SRS stakeholder types (line 41) are Students, instructors, SSG Treasurer, SSG
Advisor/Finance Monitor, campus administrators, designated access-governance
administrators, technical/Django operators, authorized university reviewers
and auditors, and system maintainers. The current login flow accepts any
approved, active non-framework account with at least one active assigned role;
it does not check a fixed role-name list. Actual database role assignments were
not inspected.

## Permission evaluation

`get_effective_permissions()` and `has_permission()` in
`apps.access_control.services` evaluate current database state. The evaluator
requires an eligible active account assignment, active service, and an active
role grant or direct grant, while active direct Deny takes precedence. The
returned permissions in the session are point-in-time UI hints only; the
backend must reauthorize every protected action.

The static catalogue at `apps/access_control/catalogue/v2_0.json` identifies
itself as planning-only. Its entries are not proof of active grants or APIs.

## Framework administrator separation

`_workspace_account()` in `apps.accounts.session_auth` excludes `is_staff` and
`is_superuser` identities from Workspace login/session. These flags are not
application roles and do not confer Workspace permissions. The SRS separately
defines Django framework operator functions.

## Authorization boundary and IDOR

**Source inspection:** IDOR is **NOT APPLICABLE to the live routes** because
there are no live object-level business APIs. Auth routes do not provide
arbitrary student, finance, clearance, academic, or announcement record
lookups.

Before any service API is exposed, it must implement and test:

- server-side permission evaluation at each protected action;
- ownership, assignment, school-period, or other approved row-scope filtering;
- cross-user ID substitution tests;
- mixed-role and conflict-of-interest checks;
- no reliance on Flutter navigation/permission hints as authorization;
- safe redaction of sensitive profile, financial, signature, and audit data.

These are requirements for future APIs, not evidence that object-level controls
already exist.

## SRS mapping notes

- FR-AUTH-05 and FR-ACL-11 require backend permission and resource-scope
  enforcement; service APIs are not routed.
- FR-ACL-01–14 describe grants, overrides, governance and role combinations.
  Models/evaluator/mutation services exist, but the mobile app has no role
  management interface or business API.
- FR-ADM-01–09 and FR-AUD-01–05 include administrative and audit workflows.
  Review API routes are inactive; no mobile administrative API is approved.
- FR-FIN-02/03/06 and FR-ACA-02/03 are personal/scoped access requirements;
  their relevant module APIs are absent.

Line-level status by requirement is in the
[Phase 3 Inspection Report](../testing/PHASE-3-INSPECTION-REPORT.md).

## Related documents

- [API Architecture](API_ARCHITECTURE.md)
- [Authentication Architecture](AUTHENTICATION_ARCHITECTURE.md)
- [Mobile API Specification](MOBILE_API_SPECIFICATION.md)
- [Phase 3 Inspection Report](../testing/PHASE-3-INSPECTION-REPORT.md)
