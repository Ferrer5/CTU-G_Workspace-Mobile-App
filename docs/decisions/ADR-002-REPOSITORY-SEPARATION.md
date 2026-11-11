# ADR-002 (Mobile Repository): Repository Separation

- **Status:** Accepted.
- **Decision:** Keep the Flutter app in its own Git repository as a sibling of
  the existing web/backend repository.

## Alternatives

- A monorepo containing web, backend, and mobile code.
- Embedding the Flutter project inside the existing web/backend repository.

## Advantages

- Separate mobile dependencies and release lifecycle.
- A clear boundary between the client and the backend's authoritative data.
- Mobile work does not require coupling the Flutter build to the protected
  backend repository.

## Disadvantages

- Cross-repository API changes need coordinated review.
- Shared contracts and release compatibility need a future process.

## Consequences

The app is at `C:\Users\Janrey\CTU-G_Workspace Mobile App`; its Git root is
independent. Phase 1 made no backend changes, added no remote, and created no
commit. No shared or linked source directory was introduced.
