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

## Decision Triggers

- **"This form is getting complicated"** → consult `references/forms.md`
- **"This component has too much logic"** → consult `references/features-and-views.md`
- **"Where does the conditional rendering logic go?"** → in the presenter, not the view

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
