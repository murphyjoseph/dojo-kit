# Plan Template

## Template

Use this template when creating a new plan in `docs/plans/`. Copy the content inside the code fence.

````markdown
# Plan: <Title>

## Scope

**What:** One-sentence summary of the work.

**Why:** The motivation — what problem this solves or what capability it adds.

**Out of scope:** Explicitly list what this plan does NOT cover. This prevents scope creep during implementation.

## Architecture Impact

**Boundaries affected:**
- List each architectural boundary (layer, feature, shared module) this work touches

**Import flow:**
- Describe how data/dependencies flow between the affected boundaries
- Call out any new imports that cross layer boundaries

**New boundaries:**
- List any new features/, shared/ modules, or platform/ services introduced
- "None" if the work stays within existing boundaries

## File Breakdown

### New Files

| File | Purpose |
|---|---|
| `src/features/example/example.tsx` | Description of what this file does |

### Modified Files

| File | Change |
|---|---|
| `src/shared/api/client.ts` | Description of modification |

### Deleted Files

| File | Reason |
|---|---|
| `src/features/old/old.tsx` | Replaced by new implementation |

## Data Flow

**End-to-end path:**
Describe the data journey from user action (or external trigger) through every layer to final output (UI update, API response, side effect).

**Error scenarios:**
- List each failure point and how it's handled
- Specify Result types or error codes where applicable

**State management:**
- What state is introduced or modified
- Where it lives (component, hook, store, URL)

## UI Plan

> Mark **N/A** for non-visual work (API-only, CLI, infrastructure).

**Components:**
- List new or modified components with their responsibility

**Form architecture** (if applicable):
- Schema file, config file, hook file, component file

**Visual states:**
- Loading, empty, error, content — describe each
- Include skeleton/placeholder strategy if relevant

## Testing Strategy

| Layer | What to test | File |
|---|---|---|
| Unit | Pure logic, transformations, utilities | `src/features/example/__tests__/example.test.ts` |
| Integration | Hook + API interaction, form submission flow | `src/features/example/__tests__/example.integration.test.ts` |
| E2E | Critical user journey | `e2e/example.spec.ts` |

## Edge Cases

| Scenario | Handling |
|---|---|
| Describe a concrete scenario | How the system responds |
| Another concrete scenario | How the system responds |

## Open Questions

- [ ] **Question text** — *who should answer: user / team lead / designer / TBD*
- [ ] **Another question** — *who should answer*

> If there are no open questions, write "None — scope is clear."

## Implementation Order

Each step is a committable unit of work.

1. **Step name** — What gets built and why this goes first
2. **Step name** — What gets built, noting dependency on step 1
3. **Step name** — Continue until the feature is complete
````

## Section Guidance

### Scope

Keep it tight. The "out of scope" list is as important as the "what" — it sets expectations and prevents the plan from growing during implementation. If you're unsure whether something is in scope, list it as an open question.

### Architecture Impact

Reference the `architecture` skill's boundary rules. Every new file must have a clear home in the import hierarchy (`routes → features/ → shared/ → platform/`). If the work introduces a new boundary, justify why it can't live in an existing one.

### File Breakdown

Use exact paths relative to the project root. Group by new/modified/deleted so the reviewer can quickly assess blast radius. If a section is empty, include the table header with a single row: "None".

### Data Flow

Trace the full path, not just the happy path. For API work, map to the four-stage pipeline from the `data-flow` skill: define → unpack → factory → consume. For each error scenario, specify whether the error is returned (Result type) or thrown (programmer error).

### UI Plan

Use the `ui-patterns` skill's form architecture (`.schema.ts` / `.controller.ts` / `.view.tsx`) for any forms. For feature components, apply the feature/view separation pattern (`.controller.ts` / `.presenter.ts` / `.view.tsx`). Mark this section N/A with a reason for non-visual work.

### Testing Strategy

Be specific — list actual test file paths that match the file breakdown. Don't write generic advice like "add tests." Each row should correspond to a concrete file from the File Breakdown section.

### Edge Cases

Concrete beats generic. "User submits with an expired session token" is useful. "Handle authentication errors" is not. Aim for 3-6 scenarios that would catch real bugs.

### Open Questions

Tag every question with who can answer it. This turns unknowns into action items. If a question blocks implementation, note which step it blocks. Resist the urge to answer your own questions here — if you knew the answer, it wouldn't be a question.

### Implementation Order

Each step should be independently committable and testable. Earlier steps should not depend on later ones. The order should minimize the time spent with broken or partial functionality.
