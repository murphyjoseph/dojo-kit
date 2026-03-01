---
name: ui-patterns
description: Form architecture and feature/view separation patterns. Use when
  building forms with validation and submission, creating components with business
  logic, separating presentation from rendering, or when a component is accumulating
  too many responsibilities.
---

# UI Patterns

Forms separate into four concerns. Features separate deciding-what-to-show from showing-it. Components don't accumulate responsibilities beyond their layer.

## Form Pattern

A form is four concerns:

| Concern | Owns | Does not own |
|---|---|---|
| **Schema** | Every field, constraint, error message | Submission, rendering, side effects |
| **Configuration** | Default values, schema wiring | Logic, API calls |
| **Submission hook** | API call, error mapping, type conversion | Rendering, navigation, what happens after success |
| **Component** | Field composition, layout, wiring the hook | Validation, fetching, deciding post-success behavior |

**The form doesn't decide what happens after success.** It fires `onSuccess`. The parent (page, modal, flow step) handles navigation, analytics, and state transitions.

```typescript
// Parent decides consequences — not the form
const handleSuccess = () => {
  trackEvent('FORM_COMPLETED');
  router.push('/next-step');
};

<MyForm onSuccess={handleSuccess} />
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
| Form with validation + submission | Form pattern (schema/config/hook/component) |
| Component with conditional logic, computed display, permission-based UI | Feature/view pattern (orchestrate/present/render) |
| Static component that receives props and renders | No pattern needed |
| Simple form with one field | Inline — the separation is overhead |

## References

- **`references/forms.md`** — Full form specification: schema design, submission hook lifecycle, error flow, `onSuccess`/`onFailure` contracts, when to simplify
- **`references/features-and-views.md`** — Feature/view specification: presenter function design, view contract typing, orchestrator wiring, when not to bother
