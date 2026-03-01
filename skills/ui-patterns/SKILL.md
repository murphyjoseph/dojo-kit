---
name: ui-patterns
description: Form architecture, feature/view separation, and testable UI composition.
  Use when building or scaffolding any component that fetches data, manages state,
  handles multiple display states (loading/empty/error/content), contains conditional
  rendering logic, or wires up forms with validation. Also use when creating new
  feature components from scratch — apply the patterns from the start, not just
  when refactoring. The goal is testability — pure presentation logic should be
  testable without rendering, and components should not mix data fetching, state
  management, and rendering in one file.
---

# UI Patterns

Forms separate API logic from rendering via a custom hook. Features separate deciding-what-to-show from showing-it. Components don't accumulate responsibilities beyond their layer.

**These are rules, not suggestions.** Apply these patterns when creating new components, not just when refactoring. Never build a monolith with the intent to split later — start separated.

**Testability is the measure.** If you can't test the display logic without mounting a component, fetching data, or mocking hooks — the separation is wrong. Presenters are pure functions. Hooks are isolated. Components are thin render layers that own zero logic.

## Form Pattern

These rules are **library-agnostic** — they apply whether you use react-hook-form, TanStack Form, Formik, or anything else. The separation is structural, not API-level.

A form separates into three concerns — the submission hook is the non-negotiable separation:

| Concern | File | Owns | Does not own |
|---|---|---|---|
| **Schema** | `item-form.schema.ts` | Every field, constraint, error message | Submission, rendering, side effects |
| **Submission hook** | `use-item-form.ts` | API calls, mutations, error mapping, payload construction, pending state | Rendering, navigation, what happens after success |
| **Component** | `item-form.tsx` | Form library setup, field composition, layout, wiring the hook | Validation logic, API calls, deciding post-success behavior |

Extract form configuration (defaults, resolver setup) into its own file when defaults are computed from server data or user preferences. For static defaults, inline in the component.

**The submission hook is mandatory.** Any form that calls an API gets a custom hook in its own file. The hook owns every mutation, every `mutateAsync` call, every payload transformation, every error mapping. It returns `{ handleSubmit, isPending, error }`. The component calls this hook — it never imports mutations directly.

**Never inline mutations in the component.** If you see `useCreateItem()` or `useMutation()` called inside a form component, that's a violation. Mutations live in the submission hook.

**The form doesn't decide what happens after success.** It fires `onSuccess`. The parent (page, modal, flow step) handles navigation, toasts, analytics, and state transitions. The form never calls `toaster`, `router.push`, or closes itself.

```typescript
// Parent — decides consequences
const handleSuccess = (data: Item) => {
  toaster.create({ title: 'Item created', type: 'success' });
  onClose();
};

<ItemForm onSuccess={handleSuccess} />
// The form knows nothing about toasts, routing, or closing dialogs.
```

### Form Anti-Pattern: The Monolith

This is what happens when the submission hook is skipped — **do not generate this**:

```typescript
// BAD — every line marked is a violation
function CreateItemPage() {
  const mutation = useMutation({ mutationFn: createItem });  // violation: mutation in component

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    mutation.mutate(payload, {
      onSuccess: () => {
        toaster.success({ title: 'Created' });               // violation: form decides consequences
        setTitle('');                                          // violation: manual field reset
      },
    });
  };
  // ... useState per field, inline rendering
}
```

The correct version has three files (schema + submission hook + component) as specified above. The form fires `onSuccess`; the parent handles toasts, navigation, and resets.

### Expected Files for a Form Feature

When scaffolding a form with an API call (e.g. "item form"), colocate all form files together:

```
features/<domain>/<concern>/
  <name>-form.schema.ts              ← Zod schema, types
  use-<name>-form.ts                 ← Submission hook
  <name>-form.tsx                    ← Thin render component
```

Never scatter these across `schemas/`, `hooks/`, `components/` directories. They belong together.

## Feature/View Pattern

A feature with state and business logic separates into three layers:

| Layer | Responsibility | Uses framework? |
|---|---|---|
| **Orchestrate** | Fetch data, manage state, own side effects | Yes (hooks, context) |
| **Present** | Pure function: raw data → view contract | No |
| **Render** | Draw the contract, fire callbacks | Yes (JSX) |

### View Contract Shape

The presenter returns a typed contract with four sections:

| Section | Contains | Example |
|---|---|---|
| `renderAs` | Which visual mode (discriminated union) | `'loading'`, `'empty'`, `'error'`, `'content'` |
| `display` | Formatted, render-ready data | Full names, date strings, labels |
| `instructions` | Boolean flags | `showError`, `disableButton`, `hideSection` |
| `effects` | Callbacks the view can fire | `onSubmit`, `onRetry`, `onDismiss` |

### Expected Files for a Feature with State

When scaffolding a component with loading/empty/error states (e.g. "team members list"), colocate presenter and view together:

```
features/<domain>/<concern>/
  <name>.presenter.ts                ← Pure presenter function
  <name>-view.tsx                    ← View component
  use-<name>.ts                      ← Orchestrator hook
```

Never put presenters in a separate `presenters/` directory — they belong next to the view they serve.

### Feature Anti-Pattern: The Kitchen Sink Component

This is what happens when orchestrate/present/render aren't separated — **do not generate this**:

```typescript
// BAD — data fetching, conditional logic, and rendering in one component
function SearchPage() {
  const { data, isLoading, error } = useQuery({ ... });       // orchestration mixed with rendering

  return (
    <>
      {isLoading ? <Skeleton /> : null}                        // violation: conditional logic in JSX
      {error ? <Text color="error">{error.message}</Text> : null}
      {data?.length === 0 ? <EmptyState /> : null}             // violation: business logic in view
      {data?.map(item => <Card key={item.id} item={item} />)}
    </>
  );
}
```

The correct version uses an orchestrator hook (owns data fetching), a presenter pure function (returns a `renderAs` contract), and a view component (narrows on `renderAs`, renders the contract).

## Mandatory Reference Loading

When creating a new form or feature component, **always** read the full reference before writing code:

- **Creating a form with an API call** → read `references/forms.md` first — it contains the complete specification, anti-patterns, and error flow
- **Creating a component with loading/empty/error states** → read `references/features-and-views.md` first — it contains the presenter pattern, contract typing, and decision guide

Do not skip reference loading when scaffolding from scratch. The references contain concrete examples and anti-patterns that prevent the most common mistakes.

### When to use each pattern

| Signal | Pattern |
|---|---|
| Form with 2+ fields or an API call | Form pattern — always (schema + submission hook + component in separate files) |
| Form with 1 field, no API call | Inline — the separation is overhead |
| Component that fetches data or has loading/empty/error states | Feature/view pattern (orchestrate/present/render) |
| Component with conditional logic, computed display, permission-based UI | Feature/view pattern (orchestrate/present/render) |
| Static component that receives props and renders | No pattern needed |

## References

- **`references/forms.md`** — Full form specification: schema design, submission hook lifecycle, error flow, `onSuccess`/`onFailure` contracts, when to simplify
- **`references/features-and-views.md`** — Feature/view specification: presenter function design, view contract typing, orchestrator wiring, when not to bother
