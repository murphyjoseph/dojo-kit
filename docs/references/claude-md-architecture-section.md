# Architecture Section for Project CLAUDE.md

When `dojo-kit-init` generates or updates a project's CLAUDE.md, inject this section. Adapt the examples to match the project's detected framework and libraries from `dojo-kit.yaml`.

---

## Section to inject

```markdown
## Architecture (dojo-kit)

### Import Hierarchy

routes → features/ → shared/ → platform/

Features are portable — no toasts, navigation, or analytics inside features. Features expose `onSuccess`/`onAction` callbacks; the route layer handles framework concerns.

### File Organization

Organize by concern, not file type. **Never create** `hooks/`, `components/`, `schemas/`, or `presenters/` directories inside features.

File naming uses functional suffixes:

| Suffix | Role |
|---|---|
| `.api.ts` | Gateway functions (fetch wrappers) |
| `.queries.ts` | Query hooks (grouped per domain) |
| `.mutations.ts` | Mutation hooks (grouped per domain) |
| `.schema.ts` | Zod validation schema |
| `.controller.ts` | Logic hook — form submission or feature orchestration |
| `.presenter.ts` | Pure function: raw data → view contract |
| `.view.tsx` | Thin render component |
| `.test.ts` | Colocated test file |
| `.styles.ts` / `.module.css` | Colocated style file |

### Feature Structure

```
features/<domain>/
  types.ts                     # Shared types
  api/
    <domain>.api.ts            # Gateway functions
    <domain>.queries.ts        # Query hooks (colocated with gateway)
    <domain>.mutations.ts      # Mutation hooks (colocated with gateway)
  <concern>/                   # e.g. create-item/, search/, dashboard/
    <name>.schema.ts           # Form: validation schema
    <name>.controller.ts       # Form: submission logic / Feature: data orchestration
    <name>.controller.test.ts  # Tests for controller logic
    <name>.view.tsx            # Form: render layer / Feature: renders presenter contract
    <name>.presenter.ts        # Feature only: pure data → view contract
    <name>.presenter.test.ts   # Tests for presenter logic
    <name>.styles.ts           # Colocated styles (if applicable)
```

### Patterns

- **Forms with API calls** → `.schema.ts` + `.controller.ts` + `.view.tsx` (never put mutations in views)
- **Data display with loading/empty/error** → `.controller.ts` + `.presenter.ts` + `.view.tsx` (presenter returns `renderAs` contract)
- **API integration** → `.api.ts` + `.queries.ts` + `.mutations.ts` in `api/` directory
```
