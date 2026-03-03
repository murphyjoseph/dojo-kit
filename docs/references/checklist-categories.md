# Checklist Audit Categories

Reference document for the `/dojo-kit-checklist` command. Defines what to audit, how to find issues, and how to classify severity.

## How to Use This Document

For each category below, follow the **search strategy** to scan the codebase. Classify each finding using the **severity guide**. Use the **example findings** as a model for how to write checklist items.

Findings should be specific and actionable — always include the file path and a concise description of the issue.

---

## 1. Error Handling

**Priority:** Critical

**Description:** Errors that are swallowed, ignored, or handled in ways that hide problems. Includes missing error boundaries in React component trees.

**Search strategy:**
- Grep for `catch` blocks — look for empty catches, catches that only log but don't re-throw or return error state
- Grep for `.catch(` on promises — same criteria
- Glob for `error-boundary` or `ErrorBoundary` — check if error boundaries exist and where they sit in the component tree (closer to the failing component is better)
- Check if top-level error boundaries exist (app-level) vs feature-level
- Look for `async` functions without try/catch or `.catch()`

**Severity guide:**
- **Critical:** Empty catch blocks, silenced errors in data-fetching or payment flows, no error boundary at all
- **High:** Error boundary only at app root (too far from components), catch blocks that log but don't surface errors to users
- **Medium:** Missing error handling in non-critical utility functions

**Example findings:**
- `src/features/checkout/api.ts:42` — empty catch block swallows payment API errors silently
- `src/features/auth/login.controller.ts:28` — async submit handler has no error handling, unhandled rejection on failure
- No feature-level error boundaries — only app-root `ErrorBoundary` exists, errors in any feature crash the entire app

---

## 2. Data Validation

**Priority:** Critical

**Description:** Missing validation at system boundaries — user input, API request/response bodies, URL parameters, environment variables.

**Search strategy:**
- Check form components — do they validate before submitting? Look for schema validation (zod, yup, valibot) or manual checks
- Check API route handlers — is the request body validated before use?
- Check API response consumption — are responses type-asserted without validation?
- Look for `process.env` usage — are env vars validated at startup?
- Check URL/search params — are they parsed and validated?

**Severity guide:**
- **Critical:** No validation on form submissions, API routes accepting unvalidated input, SQL/NoSQL queries built from unvalidated data
- **High:** API responses used without validation (runtime type mismatch risk), missing env var validation
- **Medium:** URL params used without parsing/validation in non-critical routes

**Example findings:**
- `src/app/api/users/route.ts:15` — request body spread directly into DB insert without schema validation
- `src/features/settings/profile.view.tsx:44` — form submits raw input without zod/yup schema
- `src/lib/config.ts` — `process.env.API_URL` used without startup validation, will fail silently if missing

---

## 3. Critical Gaps

**Priority:** High

**Description:** Missing pages, states, or guards that users will inevitably hit — 404 pages, loading states, auth guards, empty states.

**Search strategy:**
- Check for a 404/not-found page — Next.js: `not-found.tsx`, Remix: catch boundary or splat route, generic: a catch-all route
- Check async data-fetching components — do they have loading states?
- Check for empty states — what happens when a list has zero items?
- Look for protected routes — are auth guards in place where needed?
- Check for missing favicon, meta tags, or other baseline web concerns

**Severity guide:**
- **High:** No 404 page, no loading states on primary data views, no auth guards on protected routes
- **Medium:** Missing empty states, missing meta tags on key pages

**Example findings:**
- No 404 page — missing `not-found.tsx` or equivalent catch-all route
- `src/features/dashboard/stats.view.tsx` — fetches data on mount with no loading indicator, blank screen during fetch
- `src/features/orders/list.view.tsx` — no empty state when user has zero orders

---

## 4. Code Simplification

**Priority:** High

**Description:** Overly complex code that could be simplified without changing behavior. Long functions, deep nesting, duplicated logic, unnecessary abstractions.

**Search strategy:**
- Look for functions longer than ~50 lines — can they be decomposed?
- Look for nesting deeper than 3 levels (nested ifs, nested callbacks, nested ternaries)
- Grep for duplicated patterns — similar code blocks in multiple files
- Look for premature abstractions — wrappers that add no value, utility functions used once
- Check for overly clever code — bitwise operations for simple checks, reduce where map/filter is clearer

**Severity guide:**
- **High:** Functions over 80 lines, duplicated business logic across features, nesting 4+ levels deep
- **Medium:** Functions 50-80 lines, duplicated utility logic, unnecessary wrapper functions
- **Low:** Minor nesting that could be flattened with early returns

**Example findings:**
- `src/features/billing/invoice.controller.ts:22` — `processInvoice` is 120 lines with 5 levels of nesting, should be decomposed
- `src/features/auth/utils.ts` and `src/features/settings/utils.ts` — both implement the same role-checking logic, should be extracted to shared
- `src/lib/format.ts:45` — `formatData` wraps `JSON.stringify` with no additional logic, unnecessary abstraction

---

## 5. Code Smells

**Priority:** High

**Description:** Patterns that indicate deeper problems — magic numbers, god components, prop drilling, circular dependencies, dead code.

**Search strategy:**
- Look for magic numbers/strings — hardcoded values that should be named constants
- Check component sizes — components over ~200 lines may be doing too much
- Trace prop drilling — props passed through 3+ levels without being used by intermediate components
- Look for dead code — unused exports, commented-out code blocks, unreachable branches
- Check for circular imports — A imports B imports A

**Severity guide:**
- **High:** God components (300+ lines doing multiple things), circular dependencies, significant dead code
- **Medium:** Magic numbers in business logic, prop drilling 3+ levels, components 200-300 lines
- **Low:** Minor dead code (single unused function), hardcoded strings in non-critical paths

**Example findings:**
- `src/features/settings/settings.view.tsx` — 350-line component handling form, validation, API calls, and rendering — should be split
- `src/features/dashboard/` — `UserContext` prop-drilled through 4 levels, consider colocating or using composition
- `src/features/billing/constants.ts:12` — magic number `86400000` should be `MS_PER_DAY` constant

---

## 6. Performance

**Priority:** Medium

**Description:** Opportunities to improve runtime performance — unnecessary re-renders, missing memoization, large bundle imports, unoptimized assets.

**Search strategy:**
- Look for components that re-render on every parent render — missing `memo`, `useMemo`, `useCallback` on expensive operations
- Check for barrel file imports that pull in entire modules (`import { x } from '@/lib'` vs `import { x } from '@/lib/x'`)
- Look for large dependencies imported entirely when only a small part is used
- Check images — are they optimized? Using next/image or equivalent?
- Look for N+1 patterns — fetching in loops, sequential awaits that could be parallel

**Severity guide:**
- **High:** N+1 query patterns, importing entire lodash/moment, unoptimized images on critical pages
- **Medium:** Missing memoization on expensive computations, barrel file imports causing bundle bloat
- **Low:** Minor re-render optimizations, small images without optimization

**Example findings:**
- `src/features/search/results.view.tsx:33` — list re-renders on every keystroke, missing debounce on search input
- `src/features/analytics/chart.view.tsx:5` — imports entire `chart.js` bundle, should use tree-shakable imports
- `src/features/products/list.view.tsx:18` — fetches product details in a loop (`Promise.all` would parallelize)

---

## 7. Interactivity

**Priority:** Medium

**Description:** Missing UI feedback that makes the app feel unresponsive — loading states, pending indicators, hover/focus states, optimistic updates.

**Search strategy:**
- Check buttons that trigger async actions — do they show a pending/loading state?
- Check forms — is there feedback during submission?
- Look for navigation that loads data — are there skeleton loaders or spinners?
- Check interactive elements — do they have hover and focus styles?
- Look for opportunities for optimistic updates (e.g., toggling a favorite, marking as read)

**Severity guide:**
- **High:** No feedback on payment/checkout actions, form submission with no loading indicator
- **Medium:** Missing loading states on data views, no skeleton loaders on primary pages
- **Low:** Missing hover states, could benefit from optimistic updates but works without them

**Example findings:**
- `src/features/checkout/payment.view.tsx:55` — submit button has no disabled/loading state during payment processing
- `src/features/dashboard/` — data loads with blank screen, should use skeleton loaders
- `src/features/tasks/task-item.view.tsx` — "complete" toggle could use optimistic update for snappier feel

---

## 8. Documentation

**Priority:** Low

**Description:** Complex logic that would benefit from inline documentation — not trivial code, but genuinely complex algorithms, business rules, or non-obvious decisions.

**Search strategy:**
- Look for complex business logic — calculations, state machines, permission logic — without comments explaining the *why*
- Check public API surfaces (exported functions, component props) — are complex interfaces documented?
- Look for non-obvious code — regex patterns, bitwise operations, workarounds — without explanation
- Check for outdated comments that don't match the code

**Severity guide:**
- **Medium:** Complex business rules with no explanation, public APIs with unclear prop interfaces
- **Low:** Non-obvious utility functions without comments, outdated comments

**Example findings:**
- `src/lib/permissions.ts:22` — complex role-intersection logic with no comment explaining the business rule
- `src/features/billing/tax.ts:45` — tax calculation with magic percentages, no comment explaining which tax codes apply
- `src/lib/date-utils.ts:12` — comment says "add 1 day" but code adds 2 days

---

## 9. AI Context (CLAUDE.md)

**Priority:** Low

**Description:** Missing or outdated CLAUDE.md files that would help AI tools understand the codebase — feature-level context, architectural decisions, domain-specific terminology.

**Search strategy:**
- Check if feature directories have CLAUDE.md files — especially complex features with domain logic
- Check if the root CLAUDE.md is up to date — does it reference current commands, scripts, and structure?
- Look for complex domains (billing, auth, permissions) that would benefit from AI context
- Check if architectural decisions are documented anywhere AI tools can find them

**Severity guide:**
- **Medium:** Complex feature directories (billing, auth) with no CLAUDE.md
- **Low:** Simple features without CLAUDE.md, slightly outdated root CLAUDE.md

**Example findings:**
- `src/features/billing/` — no CLAUDE.md, complex domain with tax calculations and subscription logic undocumented for AI
- Root `CLAUDE.md` references `npm run dev` but project uses `pnpm`
- `src/features/auth/` — custom JWT refresh flow not documented, AI will misunderstand the auth pattern

---

## 10. Code Readability

**Priority:** Low

**Description:** Code that is technically correct but hard to read — inconsistent patterns, unclear naming, missing type annotations on complex types.

**Search strategy:**
- Look for inconsistent patterns across features — different conventions for similar things
- Check variable/function names — are they descriptive? Single-letter variables outside of loops?
- Look for complex return types without explicit type annotations
- Check for inconsistent file organization — some features structured differently than others

**Severity guide:**
- **Medium:** Inconsistent patterns across features causing confusion, misleading function names
- **Low:** Minor naming improvements, missing type annotations on complex inferred types

**Example findings:**
- `src/features/auth/utils.ts:18` — variable `d` should be `decodedToken` for clarity
- `src/features/` — auth uses `controller/presenter/view` pattern but settings uses flat files, should be consistent
- `src/lib/api-client.ts:30` — function `handle` doesn't describe what it handles, should be `handleApiError`
