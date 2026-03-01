---
name: architecture
description: Boundary-first architecture, file placement, and code organization.
  Use when creating new files, directories, components, hooks, or utilities —
  including during initial project scaffolding. Also use when deciding where code
  should live, resolving import questions, setting up cross-cutting services
  (logging, analytics, feature flags), or when a feature needs to share code with
  another feature. Common reusable patterns (debounce, throttle, formatters, type
  guards, custom hooks like useDebounce) belong in shared/ — recognize these during
  creation, not just when duplication appears later.
---

# Architecture

Enforce boundary-first architecture. Imports flow downward, never upward or sideways. Every file's blast radius is knowable from its location.

## Project Context

If `dojo-kit.yaml` exists at the project root, read it. Adapt the **routes** layer examples to `apps[].framework`:

- **next** (App Router) → routes layer is `app/(routes)/`, route components are `page.tsx` beside `layout.tsx`
- **remix** → routes layer is `app/routes/`, loaders and actions live in route files
- **tanstack-router** → routes layer is `routes/`, route files export `createFileRoute`
- **vite** (SPA) → routes layer is a convention you impose; no file-system router

The import hierarchy and boundary rules are framework-agnostic. Only the physical location of the routes layer and its file-naming conventions differ.

## Import Hierarchy

```
routes → features/ → shared/ → platform/
```

| Layer | Contains | Can Import | Cannot Import |
|---|---|---|---|
| **routes** | Route files, pages, layouts — the app shell | features, shared, platform | — |
| `features/` | Isolated business capabilities | shared, platform | routes, sibling features |
| `shared/` | Intentional cross-feature reuse | platform | routes, features |
| `platform/` | Infrastructure (auth, logging, i18n) | nothing above it | routes, features, shared |

The **routes** layer is whatever your framework calls it (`app/`, `routes/`, `pages/`). The name doesn't matter — the role does: it's the outermost layer that composes features and owns framework-specific wiring.

## Hard Rules

- **No sibling imports** — features cannot import from sibling features; route files cannot import from sibling route files
- **Duplication over premature abstraction** — copy code inside a feature boundary rather than creating a bad abstraction in `shared/`
- **Promotion threshold** — don't move to `shared/` until 2–3 concrete instances of the same pattern exist
- **Recognize universal utilities immediately** — well-known patterns (debounce, throttle, formatters, type guards, generic custom hooks) go directly to `shared/` — they don't need the 2–3 instance threshold because they're already proven patterns
- **Explicit coupling** — if two features need the same logic, it lives in `shared/` where the dependency is visible

## Feature Portability

**Features must be portable.** You should be able to take a feature folder (React + TypeScript) and drop it into a different app with zero changes to the feature code. This is the test for correct boundaries.

**Framework concerns stay in the routes layer.** Routing (`router.push`, `useNavigate`, `redirect`), toast/notification systems, analytics tracking, and any behavior tied to the framework or app shell lives in route-level code — never inside a feature. Features receive these as callbacks via props or dependency injection.

**Features never import from the routes layer.** A feature that calls `router.push()` is coupled to the routing framework. A feature that calls `toaster.create()` is coupled to the notification library. Instead:

| Concern | Wrong (coupled) | Right (portable) |
|---|---|---|
| Navigation | Feature calls `router.push('/items')` | Feature fires `onSuccess()`, route handles navigation |
| Toasts | Feature calls `toaster.create(...)` | Feature fires `onSuccess(data)`, route shows the toast |
| Analytics | Feature calls `trackEvent(...)` | Feature fires `onAction(...)`, route tracks the event |
| Logging | Feature imports logger directly | Feature accepts logger via context or props from `platform/` |

**The routes layer is the glue.** It composes features and wires in framework-specific behavior. This is where routing, toasts, analytics, and other app-shell concerns live. If a feature needs to trigger any of these, it exposes a callback — it never reaches for the implementation.

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
