# Codebase Health Checklist

A general-purpose checklist for auditing any web codebase. Work through each category top-to-bottom. Log findings as checkbox items under the appropriate severity level.

---

## Categories

### 1. Error Handling (Critical)

Are errors being caught, surfaced, and recovered from — or silently swallowed?

- Empty `catch` blocks that discard errors
- `.catch()` on promises that only `console.log` without re-throwing or returning error state
- Missing error boundaries in React component trees (or equivalent in your framework)
- Error boundaries too far from the source (only at app root, not feature-level)
- `async` functions with no `try/catch` or `.catch()`
- API calls with no error handling path

### 2. Data Validation (Critical)

Is data validated at every system boundary — user input, API requests, API responses, env vars?

- Forms that submit without schema validation (zod, yup, etc.)
- API route handlers that use request bodies without validating them first
- API responses consumed with type assertions but no runtime validation
- `process.env` values used without startup validation
- URL/search parameters used without parsing or type checking
- Database queries built from unvalidated input

### 3. Critical Gaps (High)

Are there missing pages, states, or guards that users will inevitably hit?

- No 404 / not-found page
- No loading states on views that fetch data asynchronously
- No empty states (what does a list show when it has zero items?)
- Missing auth guards on protected routes
- No favicon or essential meta tags
- No offline or network-error handling

### 4. Code Simplification (High)

Can any code be made simpler without changing behavior?

- Functions longer than ~50 lines
- Nesting deeper than 3 levels (nested ifs, callbacks, ternaries)
- Duplicated logic across multiple files
- Premature abstractions — wrappers or utilities used only once
- Overly clever code (bitwise ops for boolean checks, `reduce` where `map`/`filter` is clearer)

### 5. Code Smells (High)

Are there patterns that hint at deeper structural problems?

- Magic numbers or strings (hardcoded values that should be named constants)
- God components (200+ lines doing multiple unrelated things)
- Prop drilling beyond 2-3 levels
- Circular dependencies (A imports B imports A)
- Dead code — unused exports, commented-out blocks, unreachable branches
- Inconsistent abstraction levels within the same module

### 6. Performance (Medium)

Are there clear wins for runtime performance?

- Components re-rendering on every parent render (missing `memo`/`useMemo`/`useCallback` on expensive ops)
- Barrel file imports pulling in entire modules when only one export is needed
- Large dependencies imported entirely (full lodash, full chart.js)
- Unoptimized images on critical pages
- N+1 patterns — fetching in loops, sequential awaits that could be `Promise.all`
- Missing debounce/throttle on high-frequency events (scroll, resize, keystrokes)

### 7. Interactivity (Medium)

Does the UI give feedback for every user action?

- Buttons that trigger async work without a loading/disabled state
- Forms with no submission feedback (spinner, success message, error display)
- Navigation that loads data without a skeleton loader or spinner
- Interactive elements missing hover and focus styles
- Opportunities for optimistic updates (toggling favorites, marking items complete)

### 8. Documentation (Low)

Is complex logic explained where it matters?

- Business rules with no comments explaining the *why*
- Public APIs (exported functions, component props) with unclear interfaces
- Regex patterns, bitwise operations, or workarounds with no explanation
- Comments that are outdated and no longer match the code
- Non-obvious side effects that aren't documented

### 9. AI Context (Low)

Would an AI assistant (Claude, Copilot, etc.) understand this codebase?

- Complex feature directories with no `CLAUDE.md` or equivalent context file
- Root-level project docs that are outdated (wrong commands, wrong structure)
- Undocumented architectural decisions (why was this pattern chosen?)
- Domain-specific terminology with no glossary or explanation

### 10. Code Readability (Low)

Is the code easy to read for someone seeing it for the first time?

- Inconsistent patterns across features (different conventions for similar things)
- Single-letter variable names outside of loop iterators
- Complex return types with no explicit type annotation
- Inconsistent file organization (some features structured one way, others differently)
- Function names that don't describe what the function does

---

## Output Template

When logging findings, group by severity, then by category. Use checkboxes to track completion.

```markdown
# Codebase Checklist

> Last audited: YYYY-MM-DD

## Critical

### Error Handling
- [ ] `path/to/file.ts:42` — description of finding

### Data Validation
- [ ] `path/to/file.ts:15` — description of finding

## High

### Critical Gaps
- [ ] Description of finding

### Code Simplification
- [ ] `path/to/file.ts:22` — description of finding

## Medium

### Performance
- [ ] `path/to/file.ts:33` — description of finding

## Low

### Documentation
- [ ] `path/to/file.ts:45` — description of finding
```

Omit severity sections and category headings with zero findings. Mark completed items with `- [x]` and a date: `*(completed YYYY-MM-DD)*`.
