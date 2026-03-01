# Boundary-First Architecture

How to structure import boundaries so that every file's blast radius is knowable from its location.

## Quick Reference

| Rule | Description |
|---|---|
| Imports flow downward | `app/ → features/ → shared/ → platform/` — never upward, never sideways |
| No sibling imports | Features cannot import sibling features; routes cannot import sibling routes |
| Duplicate over abstract | Copy inside a boundary rather than prematurely abstracting in `shared/` |
| Promote at 2–3 instances | Only move to `shared/` when the pattern has proven itself concretely |

## Layer Specification

### `app/`

Routes, pages, and layouts. High churn, low blast radius. Each route is private by default — route-specific logic, components, and state live within the route directory.

```
app/
  home/
  dashboard/
  settings/
```

**Can import:** features, shared, platform
**Cannot import:** sibling routes

### `features/`

Isolated business capabilities. Each feature owns its components, hooks, utils, and types. No feature knows another feature exists.

```
features/
  checkout/
  cart/
  profile/
```

**Can import:** shared, platform
**Cannot import:** app, sibling features

### `shared/`

Intentional cross-feature reuse. Code arrives here only after proving it belongs — not speculatively.

```
shared/
  hooks/
  utils/
  components/
```

**Can import:** platform
**Cannot import:** app, features

### `platform/`

Infrastructure. Auth, logging, i18n, API clients. Stable, rarely changed, no knowledge of what consumes it.

```
platform/
  api/
  auth/
  logging/
```

**Can import:** nothing above it
**Cannot import:** app, features, shared

## Import Resolution Rules

When code in one feature needs something from another feature, there are two paths:

### Path 1: Promote to `shared/`

Use when the abstraction is clean and proven across 2–3 concrete instances.

```typescript
// Before (violation — checkout imports from cart)
import { useCartItems } from '../cart/hooks/useCartItems';

// After (promoted to shared)
import { useCartItems } from '@/shared/hooks/useCartItems';
```

Both features now import from `shared/`. The dependency is visible, intentional, and maintained in one place.

### Path 2: Duplicate

Use when a clean abstraction doesn't exist yet.

```typescript
// checkout/hooks/useCheckoutItems.ts — checkout's own version
// cart/hooks/useCartItems.ts — cart's own version
```

Duplication inside a feature boundary is cheap to fix later. A premature abstraction in `shared/` couples features around the wrong seam and is expensive to unwind.

## Promotion Criteria

Before moving code to `shared/`, verify:

1. **At least 2–3 concrete instances** of the same pattern exist across features
2. **The abstraction is obvious** — you can see what varies and what doesn't
3. **The interface is stable** — consumers agree on the contract
4. **The code has no feature-specific assumptions** — it works generically

## Decision Guide

| Situation | Action |
|---|---|
| Feature A needs logic from Feature B | Duplicate inside Feature A, or promote to `shared/` if criteria met |
| Utility is used by one feature | Keep it in the feature |
| New cross-cutting concern (logging, auth) | Place in `platform/` |
| Layout or page-level component | Place in `app/` route directory |
| Shared UI component (design system) | Place in `shared/components/` |
| Not sure where it goes | Start in the feature. Promote later when the pattern is clear. |
