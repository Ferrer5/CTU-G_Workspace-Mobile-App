# ADR-003 (Mobile Repository): Feature-Oriented Architecture

- **Status:** Accepted for future feature growth; Phase 1 remains intentionally
  small.
- **Decision:** Keep app-wide infrastructure in `app/` and `core/`; place
  future feature code under `features/<name>/` with presentation/data and a
  domain layer only when needed.

## Alternatives

- Layer-first directories for all screens, data sources, and models.
- Creating empty feature modules for anticipated product areas.

## Advantages

- Feature-specific code can remain cohesive as real capabilities are added.
- Shared configuration and app startup are separate from product features.
- Avoids premature dependencies and placeholder APIs.

## Disadvantages

- Feature boundaries require future judgment to avoid duplication.
- A small starter app gains little immediate benefit from deep architecture.

## Why no empty feature modules

Phase 1 authorizes foundation only and specifies that empty feature folders and
placeholder services must not be created. Directories are created only where
real files exist. Future features may use
`features/<name>/{presentation,data,domain-if-needed}/` after explicit
authorization and feature requirements.
