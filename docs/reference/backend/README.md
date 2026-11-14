# Backend reference snapshots

This directory contains read-only reference snapshots copied from the protected backend repository at `C:\Users\Janrey\CTU-G_Workspace` for Phase 4 investigation only. These files are not source-of-truth code and must not be edited.

## Source repository

- Original repository: `C:\Users\Janrey\CTU-G_Workspace`
- Original branch: `ronald` (as observed in the protected repo at the time of inspection)
- Source commit: `9594a0219c79670cf26b2f360b37d9756d5e62a6`
- Working tree state at copy time: clean (no tracked or untracked changes observed)
- Inspection/copy date: `2026-11-14`
- Future backend-change authority: owner/approver `[YOUR NAME]`; backend developer `[NAME]`; branch `[BRANCH NAME]`.

## Files copied

| Original path | Destination file | Purpose |
|---|---|---|
| `docs/SRS/CTU-G_Workspace_SRS_v1.md` | `CTU-G_Workspace_SRS_v1.md` | SRS baseline and scope statement; note that the file name is v1 but the document text says v0.3 PROPOSED FOR REVIEW. |
| `docs/DEVELOPMENT_STATUS.md` | `DEVELOPMENT_STATUS.md` | Project development status and current implementation status notes. |
| `docs/README.md` | `BACKEND_DOCS_README.md` | Backend project documentation index and context. |
| `docs/api/AUTH_ENDPOINT_INVENTORY.md` | `AUTH_ENDPOINT_INVENTORY.md` | Authentication endpoint inventory and draft contract summary. |
| `docs/implementation/authentication/phase2-registration.md` | `phase2-registration.md` | Registration workflow and implementation notes. |
| `docs/implementation/authentication/ar-6c3-integration-readiness-assessment.md` | `ar-6c3-integration-readiness-assessment.md` | Readiness assessment for backend integration work. |
| `docs/implementation/authentication/PASSWORD_RECOVERY.md` | `PASSWORD_RECOVERY.md` | Supporting password recovery notes and scope details. |
| `docs/decisions/ADR-001-admin-identity-separation.md` | `ADR-001-admin-identity-separation.md` | Decision record for admin identity separation. |
| `docs/decisions/ADR-003-django-framework-account-flags.md` | `ADR-003-django-framework-account-flags.md` | Decision record for framework account flags and account behavior. |

## Reference SHA-256 table

| File | SHA-256 |
|---|---|
| `CTU-G_Workspace_SRS_v1.md` | `AF4EAD4F88BDB0877AB6C3B8965BEC5CAF0F058D74AB0D878EC690379210346F` |
| `DEVELOPMENT_STATUS.md` | `5009ADA6D3CD8151C26C5E53C20A781D3D1EA824D8286031C7150E3C1B1F6677` |
| `BACKEND_DOCS_README.md` | `8FAADB9869C6F907423B739945CB31AFC5A230EE9CF392B1E699A3D2DA6F8F9C` |
| `AUTH_ENDPOINT_INVENTORY.md` | `7EF26FAC0AE6B0C361EEEA9636D3055210C92C8A68380B7626F5F302CDC7AFA1` |
| `phase2-registration.md` | `E6322C45FE84AE923B34A8A5463A02C8872C43D987911DC56CFAB075411122A3` |
| `ar-6c3-integration-readiness-assessment.md` | `4424FBE855CCAE9DE7CEF3EE51D09099994956F79A7C9D73BB6BE01F0E4ADE04` |
| `PASSWORD_RECOVERY.md` | `CC5444799D2484F8153C16B7EC4D132B93BE93DF792231B8795806817D2987A2` |
| `ADR-001-admin-identity-separation.md` | `805C9E6881D7029ADDDA5F10F0D5845054E6394911AD3E9C915255470E409823` |
| `ADR-003-django-framework-account-flags.md` | `EF63700A7ACC717C645C9AD46E28A22A58B19B39794DE817652BFC1C68F1000F` |

## Baseline capture record

Protected backend baseline at Turn 1 and after this documentation step:

| Capture | Value |
|---|---|
| `git rev-parse HEAD` | `9594a0219c79670cf26b2f360b37d9756d5e62a6` |
| `git status --porcelain` | empty output |
| `git diff --stat` | empty output |
| SHA-256 of `git diff` | `E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855` |

This matches the Turn 1 backend baseline. The protected backend remained unchanged and was not modified by this work.

## Important notes

- These are READ-ONLY REFERENCE SNAPSHOTS that may be outdated relative to the live backend repository.
- The SRS file is named `CTU-G_Workspace_SRS_v1.md`, but its document content states `Version: 0.3 — Revised Access-Control Architecture...` and `Status: PROPOSED FOR REVIEW — NOT IMPLEMENTATION OR DATABASE-WRITE APPROVAL`.
- Do not treat these files as approved implementation or deployment authorization.
- Re-verify every contract against the actual backend source code before implementing or testing any mobile authentication behavior.
- Backend changes are not approved in this phase; if a backend change is later required, it must be proposed separately and remain outside this mobile-only documentation branch.
