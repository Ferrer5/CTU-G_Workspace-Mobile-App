No backend modifications were made during Phase 1.

# Proposed future changes (NOT implemented)

- Configure LAN `ALLOWED_HOSTS` if required (the supplied snapshot shows
  `ALLOWED_HOSTS = []`).
- Configure CORS only if the eventual architecture requires it; a native
  client may not need browser CORS.
- Design mobile token endpoints and authentication contract.
- Define and validate account eligibility/registration approval for mobile.
- Integrate authoritative RBAC/permission decisions for mobile requests.
- Add the mobile-side `INTERNET` permission only when networking is authorized
  and implemented. No permission was added to the main manifest in Phase 1.
