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

Forms separate into four concerns. Features separate deciding-what-to-show from showing-it. Components don't accumulate responsibilities beyond their layer.

**These are rules, not suggestions.** Apply these patterns when creating new components, not just when refactoring. Never build a monolith with the intent to split later — start separated.

**Testability is the measure.** If you can't test the display logic without mounting a component, fetching data, or mocking hooks — the separation is wrong. Presenters are pure functions. Hooks are isolated. Components are thin render layers that own zero logic.

## Project Context

If `dojo-kit.yaml` exists at the project root, read it. Adapt form examples to match `libraries.forms` and `libraries.validation`:

- **forms:** `react-hook-form` → `useForm`, `zodResolver` (default). `formik` → `useFormik`, `validationSchema`. `react-form` → `useForm` from `@tanstack/react-form`.
- **validation:** `zod` → `z.object(...)` (default). `yup` → `yup.object(...)`. `valibot` → `v.object(...)`.

The four-concern structure and onSuccess/onFailure contract are the same regardless of library. Only the form wiring API changes.

## Form Pattern

A form is four separate concerns — **each in its own file**, not combined:

| Concern | File | Owns | Does not own |
|---|---|---|---|
| **Schema** | `item-form.schema.ts` | Every field, constraint, error message | Submission, rendering, side effects |
| **Configuration** | `item-form.config.ts` | Default values, schema wiring, resolver setup | Logic, API calls |
| **Submission hook** | `use-item-form.ts` | API call, error mapping, type conversion | Rendering, navigation, what happens after success |
| **Component** | `item-form.tsx` | Field composition, layout, wiring the hook | Validation, fetching, deciding post-success behavior |

**Never put the schema, submission logic, and component in the same file.** The schema is independently importable for testing and reuse. The submission hook is testable without rendering. The component is a thin render layer that calls the hook.

**Never manage form field state with `useState`.** Use the project's form library (react-hook-form, formik, etc.) wired to the schema via the configuration. Manual `useState` per field, `useEffect` to sync values, and inline `safeParse` calls are all violations.

**The form doesn't decide what happens after success.** It fires `onSuccess`. The parent (page, modal, flow step) handles navigation, toasts, analytics, and state transitions. The form never calls `toaster`, `router.push`, or closes itself.

```typescript
// Route or page — the app/ layer — decides consequences
// This is where framework-specific concerns (toasts, routing, analytics) live
const handleSuccess = (data: Item) => {
  toaster.create({ title: 'Item created', type: 'success' });
  trackEvent('ITEM_CREATED', { id: data.id });
  onClose();
};

<ItemForm onSuccess={handleSuccess} />
// The form knows nothing about toasts, routing, or analytics.
// It just calls onSuccess with the created data. Portable.
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
| Form with 2+ fields and validation | Form pattern — always (schema/config/hook/component in separate files) |
| Form with 1 field, no API call | Inline — the separation is overhead |
| Component that fetches data or has loading/empty/error states | Feature/view pattern (orchestrate/present/render) |
| Component with conditional logic, computed display, permission-based UI | Feature/view pattern (orchestrate/present/render) |
| Static component that receives props and renders | No pattern needed |

## References

- **`references/forms.md`** — Full form specification: schema design, submission hook lifecycle, error flow, `onSuccess`/`onFailure` contracts, when to simplify
- **`references/features-and-views.md`** — Feature/view specification: presenter function design, view contract typing, orchestrator wiring, when not to bother
