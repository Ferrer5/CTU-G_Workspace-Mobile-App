# System Architecture

This mobile-repository document distinguishes the existing system (facts from
the supplied backend snapshot, not re-verified against the live repository)
from planned integration.

## Responsibilities and boundaries

| Area | Status | Responsibility |
|---|---|---|
| CTU-G web application | EXISTING (snapshot) | React + TypeScript + Vite browser client; browser session and CSRF authentication. |
| Django + DRF backend | EXISTING (snapshot) | Server-side API and authoritative business behavior. |
| MySQL | EXISTING (snapshot) | Backend persistence. The mobile app does not connect to MySQL. |
| Flutter Android app | EXISTING (Phase 1 foundation); PLANNED (future REST client) | Independent Android app. Phase 1 has no networking or authoritative data; future REST integration requires authorization. |
| Future mobile authentication | PLANNED | Token-based mobile authentication may be considered. It is not implemented and no endpoint contract is assumed. |

## Integration boundary

- EXISTING (snapshot): the web application and backend are in
  `C:\Users\Janrey\CTU-G_Workspace`; this mobile repository is a sibling at
  `C:\Users\Janrey\CTU-G_Workspace Mobile App`.
- EXISTING (snapshot): the backend snapshot uses MySQL and Django/DRF; its
  routed API inventory contains authentication endpoints under
  `/api/v1/auth/`.
- PLANNED: a future mobile client calls Django over REST on the LAN or another
  explicitly approved network. It will not connect directly to MySQL.
- PLANNED: backend session+CSRF behavior remains the web application's
  authentication mechanism. A mobile token strategy requires backend and
  product decisions before implementation.
- Phase 1 has no HTTP package, networking source code, endpoint calls, secrets,
  or network configuration. Its URL is configuration data only.

## Security and authority

EXISTING (snapshot): Django is the server-side system of record; the mobile
client must not become an authority for roles, permissions, eligibility, or
business data. PLANNED: the backend will make authoritative authorization
decisions for any future mobile requests. Effective mobile permissions,
account eligibility, and transport security are open questions, not established
facts.
