# Checklist Command Design

**Date:** 2026-03-02
**Status:** Approved

## Overview

A new `/dojo-kit-checklist` command that audits the user's app codebase across 10 health categories and outputs a prioritized, trackable `docs/CHECKLIST.md` with markdown checkboxes.

## Architecture

**Approach:** Command + Reference Doc (progressive disclosure)

| File | Purpose | ~Size |
|------|---------|-------|
| `commands/dojo-kit-checklist.md` | Orchestration — flow, interactivity, merge logic, output format | ~80 lines |
| `docs/references/checklist-categories.md` | Category definitions — what to scan, severity guides, search strategies | ~150 lines |

## Command Behavior

- **Scope:** User's app codebase only (not dojo-kit internals)
- **Execution:** Interactive — pauses after each category for user to approve/skip/give feedback
- **Re-runs:** Merge & update — reads existing `docs/CHECKLIST.md`, preserves `- [x]` completed items, removes stale findings, adds new ones
- **Tracking:** Markdown checkboxes (`- [ ]` / `- [x]`)
- **Naming:** `/dojo-kit-checklist` (follows `dojo-kit-*` prefix convention)
- **Allowed tools:** `Read`, `Write`, `Edit`, `Glob`, `Grep`, `Bash(ls:*)`, `AskUserQuestion`

## Orchestration Flow

1. Check for existing `docs/CHECKLIST.md` — if found, read and parse completed items
2. Read `docs/references/checklist-categories.md` to load audit categories
3. For each category (in priority order):
   - Scan codebase for findings relevant to that category
   - Present findings summary via `AskUserQuestion` — options: "Add these findings", "Skip this category", "Let me give feedback"
   - Collect approved findings
4. Merge results — preserve completed items, add new findings, remove stale items
5. Write `docs/CHECKLIST.md` — grouped by severity, then by category, with checkboxes

## Audit Categories

| # | Category | Default Priority | Focus |
|---|----------|-----------------|-------|
| 1 | Error Handling | Critical | Silenced catches, missing error boundaries, unhandled rejections |
| 2 | Data Validation | Critical | Missing input validation at boundaries, unvalidated API responses |
| 3 | Critical Gaps | High | Missing 404 page, no loading states, absent auth guards |
| 4 | Code Simplification | High | Complex functions, deep nesting, duplicated logic |
| 5 | Code Smells | High | Magic numbers, god components, prop drilling, dead code |
| 6 | Performance | Medium | Unnecessary re-renders, missing memoization, large imports |
| 7 | Interactivity | Medium | Missing loading/pending states, no skeleton loaders |
| 8 | Documentation | Low | Complex logic without comments, missing JSDoc on public APIs |
| 9 | AI Context (CLAUDE.md) | Low | Missing CLAUDE.md in feature dirs, outdated project CLAUDE.md |
| 10 | Code Readability | Low | Inconsistent patterns, unclear naming, missing type annotations |

Each category in the reference doc includes:
- **Description** — what the category covers
- **Search strategy** — files/patterns to scan
- **Severity guide** — how to classify findings within the category
- **Example findings** — 2-3 concrete checklist item examples

## Output Format (`docs/CHECKLIST.md`)

```markdown
# Codebase Checklist

> Last audited: 2026-03-02

## Critical

### Error Handling
- [ ] `src/features/checkout/api.ts` — catch block on L42 swallows error silently
- [x] `src/lib/api-client.ts` — missing error handling on fetch wrapper *(completed 2026-03-01)*

### Data Validation
- [ ] `src/app/api/users/route.ts` — request body not validated before DB write

## High

### Critical Gaps
- [ ] No 404 page — missing `not-found.tsx` or equivalent catch-all route

...

## Low

### AI Context
- [ ] `src/features/billing/` — no CLAUDE.md, complex domain logic undocumented
```

**Format rules:**
- Grouped by severity (Critical → High → Medium → Low), then by category
- Each item: `- [ ]` + file path + concise description
- Completed items: `- [x]` with completion date note
- Last-audited date at top
- On re-runs: completed items preserved, stale items removed, new items appended
