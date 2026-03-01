---
name: scaffolding
description: Orchestrate feature scaffolding with correct architecture patterns.
  Use when creating a new page, route, feature, component, form, search view,
  list view, detail view, CRUD interface, or any UI that calls an API. Also use
  when the user says build, scaffold, generate, wire up, or create for any
  frontend work. This skill coordinates architecture, ui-patterns, data-flow,
  and project-standards so they apply together — not in isolation.
---

# Scaffolding

When creating any new feature, page, or component that touches an API or manages state, apply dojo-kit patterns from the start. Never scaffold a monolith with the intent to refactor later.

**This skill orchestrates other skills.** You must consult each one during scaffolding — they are not optional.

## Scaffolding Checklist

Before writing any code for a new feature, page, or component:

1. **Architecture** (`architecture` skill) — determine which layer each file belongs to (routes, features, shared, platform). Map the import flow. Identify if any new shared or platform code is needed.

2. **File structure** (`project-standards` skill) — name every file in kebab-case with functional suffixes. Plan the directory layout. No barrel files.

3. **API integration** (`data-flow` skill) — if the feature calls any API, create the pipeline files (definition, unpack, factory, consumer hook). Set up Result types. Never call `fetch()` from feature code.

4. **Component structure** (`ui-patterns` skill):
   - **Forms with API calls** → always create three files: schema, submission hook, component. Consult `ui-patterns/references/forms.md` for the full specification.
   - **Data display with loading/empty/error states** → always create three layers: orchestrator hook, presenter function, view component. Consult `ui-patterns/references/features-and-views.md` for the full specification.

5. **Feature portability** (`architecture` skill) — verify features don't import from routes or sibling features. Toasts, navigation, and analytics happen via `onSuccess`/`onAction` callbacks, never inside the feature.

## Output: What a Scaffolded Feature Looks Like

### Colocation Principle

**Organize by concern, not by file type.** Never create type-based directories like `hooks/`, `schemas/`, `presenters/`, `components/` that scatter related files. Instead, colocate files that work together. Shared types and API files live at the feature root or in `api/`. Each concern (form, dashboard, search) gets its own sub-directory when the feature has multiple concerns.

### Form feature (e.g. "create item")

```
features/items/
  types.ts                           ← Shared type definitions
  api/
    items.api.ts                     ← Gateway functions
    items.unpack.ts                  ← Response → Result normalization
  create-item/
    item-form.schema.ts              ← Zod schema, single validation truth
    use-item-form.ts                 ← Submission hook: mutations, error mapping, isPending
    item-form.tsx                    ← Thin render layer: form library setup + fields
```

The route file composes the feature and handles consequences:

```typescript
// routes/create-item/index.tsx
<ItemForm onSuccess={(item) => {
  toaster.create({ title: 'Item created', type: 'success' });
  navigate({ to: '/items/$id', params: { id: item.id } });
}} />
```

### Data display feature (e.g. "search items")

```
features/items/
  types.ts                           ← Shared type definitions
  api/
    items.api.ts                     ← Gateway functions
    items.unpack.ts                  ← Response → Result normalization
  search/
    search.presenter.ts              ← Pure function: data → view contract with renderAs
    search-view.tsx                  ← Renders the contract, no logic
    use-search-items.ts              ← Orchestrator: fetches data, manages state
```

## What NOT to Generate

These are violations — if you see these patterns in your output, stop and fix them:

| Violation | Correct approach |
|---|---|
| `useMutation()` inside a form component | Move to submission hook |
| `toaster.create()` inside a feature | Fire `onSuccess`, let route handle toasts |
| `router.push()` inside a feature | Fire `onSuccess`, let route handle navigation |
| `useState` per field instead of a form library + schema | Use schema file + form library |
| Inline `fetch()` or direct API client call in feature | Use the API pipeline (define/unpack/factory/consume) |
| Loading/empty/error handled with inline ternaries in one component | Use presenter + view contract with `renderAs` |
| All logic in one file | Split by concern: schema, hook, component (forms) or orchestrator, presenter, view (features) |
| Type-based directories (`hooks/`, `schemas/`, `components/`, `presenters/`) | Colocate by concern — related files live together in the same directory |

## When to Simplify

Not every page needs the full pipeline. Use judgment:

| Situation | Approach |
|---|---|
| Static page with no API calls or state | No pattern needed — just a component |
| Simple display with one API call, no error/empty states | Orchestrator hook + component (skip presenter) |
| Form with 1 field, no API call | Inline — the separation is overhead |
| Prototype or proof of concept | Note that patterns are skipped, apply later |
