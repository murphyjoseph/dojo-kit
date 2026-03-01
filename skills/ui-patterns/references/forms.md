# Forms

How to structure forms so that validation, submission, and rendering are separate, testable concerns. These patterns are **library-agnostic** — they work the same with react-hook-form, TanStack Form, Formik, or any other form library.

## Quick Reference

| Rule | Description |
|---|---|
| Controller is mandatory | Any form with an API call gets a `.controller.ts` in its own file |
| Mutations never live in the view | `useCreateItem()`, `useMutation()` etc. belong in the controller |
| One schema is the validation truth | Nothing else validates — not the view, not the handler |
| The form doesn't decide what happens next | It fires `onSuccess`; the parent handles consequences |

## The Three Concerns

### 1. Schema (Validation Truth)

One schema defines every field, every constraint, every error message. The schema is independently importable — it can be tested without rendering and reused across contexts.

```typescript
// features/items/create-item/item-form.schema.ts
import { z } from 'zod';

export const itemFormSchema = z.object({
  title: z.string().min(1, 'Title is required'),
  description: z.string().optional(),
  priority: z.number().int().min(1).max(5),
  status: z.enum(['todo', 'in_progress', 'done']),
});

export type ItemFormValues = z.infer<typeof itemFormSchema>;
```

**Testable without rendering:** pass an object, assert valid or invalid.

### 2. Controller (Non-Negotiable)

This is the critical separation. The controller owns every API call, mutation, payload transformation, and error mapping. It returns a submit handler and state — nothing about rendering.

```typescript
// features/items/create-item/item-form.controller.ts

interface UseItemFormOptions {
  item?: Item | null;
  onSuccess: (item: Item) => void;
}

export function useItemForm({ item, onSuccess }: UseItemFormOptions) {
  const createMutation = useCreateItem();
  const updateMutation = useUpdateItem();
  const isEdit = !!item;

  const handleSubmit = async (values: ItemFormValues) => {
    const payload = {
      title: values.title,
      description: values.description || undefined,
      priority: values.priority,
      status: values.status,
    };

    if (isEdit && item) {
      const updated = await updateMutation.mutateAsync({
        id: item.id,
        data: payload,
      });
      onSuccess(updated);
    } else {
      const created = await createMutation.mutateAsync(payload);
      onSuccess(created);
    }
  };

  return {
    handleSubmit,
    isPending: createMutation.isPending || updateMutation.isPending,
    error: createMutation.error || updateMutation.error,
  };
}
```

**Testable without UI:** mock the mutations, call the hook, assert payload shape and error handling.

**What lives here:**
- Every `useCreateX()`, `useUpdateX()`, `useMutation()` call
- Payload construction and type conversion
- Create vs update branching
- Server error mapping to form-level or field-level errors
- Pending state derivation

**What does NOT live here:**
- Form library setup (`useForm`, resolvers, default values)
- Rendering or JSX
- Navigation, toasts, or dialog closing (that's `onSuccess`)

### 3. View (Thin Render Layer)

The view sets up the form library, composes fields, and wires the controller. It does not import mutations, construct payloads, or decide what happens after success.

```typescript
// features/items/create-item/item-form.view.tsx

interface ItemFormProps {
  item?: Item | null;
  onSuccess: (item: Item) => void;
}

export function ItemForm({ item, onSuccess }: ItemFormProps) {
  const { handleSubmit, isPending, error } = useItemForm({ item, onSuccess });

  // Form library setup lives here — this is fine
  const form = useForm({
    defaultValues: {
      title: item?.title ?? '',
      description: item?.description ?? '',
      priority: item?.priority ?? 3,
      status: item?.status ?? 'todo',
    },
    onSubmit: async ({ value }) => handleSubmit(value),
    // ...library-specific config (resolver, validators, etc.)
  });

  return (
    <form onSubmit={/* library-specific submit wiring */}>
      {error && <FormBanner message={error.message} />}
      {/* Field composition — library-specific */}
      <SubmitButton loading={isPending}>
        {item ? 'Save' : 'Create'}
      </SubmitButton>
    </form>
  );
}
```

**The view imports the controller, not the mutations.** If you see `useCreateItem()` or `useMutation()` in a `.view.tsx` file, that's a violation.

## Anti-Pattern: The Monolith Form

This is what happens when the controller is skipped. Everything ends up in one file:

```typescript
// BAD — mutations, payload construction, and rendering in one file
export function ItemForm({ item, onOpenChange }) {
  const createMutation = useCreateItem();      // violation: mutation in view
  const updateMutation = useUpdateItem();      // violation: mutation in view

  const form = useForm({
    defaultValues: { /* ... */ },
    onSubmit: async ({ value }) => {
      const payload = { /* ... */ };            // violation: payload construction in view
      if (isEdit) {
        await updateMutation.mutateAsync(...);  // violation: API call in view
      } else {
        await createMutation.mutateAsync(...);  // violation: API call in view
      }
      onOpenChange(false);                      // violation: form decides what happens after success
    },
  });

  return ( /* 80+ lines of JSX */ );
}
```

**Why this fails:**
- Can't test submission logic without rendering the entire form
- Can't reuse the submission logic in a different context (modal vs page vs multi-step)
- The form decides to close itself (`onOpenChange(false)`) instead of letting the parent decide
- Mutations, payload logic, and rendering are tangled — changing one risks breaking the others

## Error Flow

```
Client-side validation fails
  → Schema error messages appear on fields (handled by form library)

Server-side validation fails
  → Controller maps field errors back to the form

Unexpected server error
  → Controller surfaces a form-level error

Network error
  → Controller surfaces a form-level error (or retry prompt)
```

Each error type has exactly one handler. No ambiguity about which layer handles which kind of failure.

## The Form Doesn't Decide What Happens Next

The form fires callbacks. The parent handles consequences.

```typescript
// Parent — decides navigation, tracking, toasts, dialog closing
function ItemDialog({ open, onOpenChange }) {
  const handleSuccess = (item: Item) => {
    toaster.create({ title: `Item ${item.id ? 'updated' : 'created'}`, type: 'success' });
    onOpenChange(false);  // parent closes the dialog, not the form
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <ItemForm onSuccess={handleSuccess} />
    </Dialog>
  );
}
```

This means the same form works in a full page, a modal, a multi-step flow, or a settings panel — without changes.

## Extract Configuration When Needed

Form library setup (default values, resolver, validation wiring) lives in the view by default. Extract it into its own hook when:

| Signal | Action |
|---|---|
| Defaults are computed from server data or user preferences | Extract `useItemFormConfig()` |
| Multiple views use the same form setup | Extract shared config hook |
| Static defaults, simple form | Inline in the view — no need to extract |

## Decision Guide

| Situation | Action |
|---|---|
| Form with an API call | Extract controller — always |
| Form with 2+ fields and validation | Schema in its own file, controller in its own file |
| Simple form (1–2 fields, no API call) | Inline everything in one component |
| Submit handler > 10 lines | Extract controller |
| Same form in multiple contexts | Ensure `onSuccess`/`onFailure` props, not hardcoded behavior |
| Need to test submission logic without rendering | Extract controller |
| Form needs computed defaults from server data | Extract configuration hook |
