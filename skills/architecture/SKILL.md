---
name: architecture
description: Boundary-first architecture and service patterns. Use when creating
  new files or directories, deciding where code should live, resolving import
  questions, setting up cross-cutting services (logging, analytics, feature flags),
  or when a feature needs to share code with another feature.
---

# Architecture

Enforce boundary-first architecture. Imports flow downward, never upward or sideways. Every file's blast radius is knowable from its location.

## Project Context

If `dojo-kit.yaml` exists at the project root, read it. Adapt `app/` layer examples to `apps[].framework`:

- **next** (App Router) → `app/` maps to `app/(routes)/`, route components are `page.tsx` beside `layout.tsx`
- **remix** → `app/` maps to `app/routes/`, loaders and actions live in route files
- **vite** (SPA) → `app/` is a convention you impose; no file-system router

The import hierarchy and boundary rules are framework-agnostic. Only the physical location of the `app/` layer and its file-naming conventions differ.

## Import Hierarchy

```
app/ → features/ → shared/ → platform/
```

| Layer | Contains | Can Import | Cannot Import |
|---|---|---|---|
| `app/` | Routes, pages, layouts | features, shared, platform | — |
| `features/` | Isolated business capabilities | shared, platform | app, sibling features |
| `shared/` | Intentional cross-feature reuse | platform | app, features |
| `platform/` | Infrastructure (auth, logging, i18n) | nothing above it | app, features, shared |

## Hard Rules

- **No sibling imports** — features cannot import from sibling features; routes cannot import from sibling routes
- **Duplication over premature abstraction** — copy code inside a feature boundary rather than creating a bad abstraction in `shared/`
- **Promotion threshold** — don't move to `shared/` until 2–3 concrete instances of the same pattern exist
- **Explicit coupling** — if two features need the same logic, it lives in `shared/` where the dependency is visible

## Services

Cross-cutting concerns (logging, analytics, feature flags) follow a three-step pattern:

| Step | What happens | Who sees it |
|---|---|---|
| **Create** | Singleton instance with base config | Platform code |
| **Initialize** | Environment-specific handlers (browser SDK, server API key) | Bootstrap code |
| **Use** | Stable public interface (`logger.info()`, `flags.isEnabled()`) | Feature code |

Feature code only sees the interface. The vendor is an implementation detail.

## Decision Triggers

- **"Where does this file go?"** → consult `references/boundary.md`
- **"How do I set up logging/analytics/flags?"** → consult `references/services.md`
- **"Should I share this across features?"** → if fewer than 2–3 instances, duplicate instead

## References

- **`references/boundary.md`** — Full boundary specification: layer rules, import direction, promotion criteria, enforcement patterns
- **`references/services.md`** — Service pattern specification: create/initialize/use lifecycle, initialization order, structured logging conventions
