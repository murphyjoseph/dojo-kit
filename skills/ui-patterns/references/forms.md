# Forms

How to structure forms so that validation, submission, and rendering are separate, testable concerns. These patterns are **library-agnostic** — they work the same with react-hook-form, TanStack Form, Formik, or any other form library.

## Quick Reference

| Rule | Description |
|---|---|
| Submission hook is mandatory | Any form with an API call gets a custom hook in its own file |
| Mutations never live in the component | `useCreateItem()`, `useMutation()` etc. belong in the submission hook |
| One schema is the validation truth | Nothing else validates — not the component, not the handler |
| The form doesn't decide what happens next | It fires `onSuccess`; the parent handles consequences |

## The Three Concerns

### 1. Schema (Validation Truth)

One schema defines every field, every constraint, every error message. The schema is independently importable — it can be tested without rendering and reused across contexts.

```typescript
// features/items/schemas/item-form.schema.ts
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

### 2. Submission Hook (Non-Negotiable)

This is the critical separation. The submission hook owns every API call, mutation, payload transformation, and error mapping. It returns a submit handler and state — nothing about rendering.

```typescript
// features/items/hooks/use-item-form.ts

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

### 3. Component (Thin Render Layer)

The component sets up the form library, composes fields, and wires the submission hook. It does not import mutations, construct payloads, or decide what happens after success.

```typescript
// features/items/components/item-form.tsx

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

**The component imports the submission hook, not the mutations.** If you see `useCreateItem()` or `useMutation()` in a form component file, that's a violation.

## Anti-Pattern: The Monolith Form

This is what happens when the submission hook is skipped. Everything ends up in one component:

```typescript
// BAD — mutations, payload construction, and rendering in one file
export function ItemForm({ item, onOpenChange }) {
  const createMutation = useCreateItem();      // violation: mutation in component
  const updateMutation = useUpdateItem();      // violation: mutation in component

  const form = useForm({
    defaultValues: { /* ... */ },
    onSubmit: async ({ value }) => {
      const payload = { /* ... */ };            // violation: payload construction in component
      if (isEdit) {
        await updateMutation.mutateAsync(...);  // violation: API call in component
      } else {
        await createMutation.mutateAsync(...);  // violation: API call in component
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
  → Submission hook maps field errors back to the form

Unexpected server error
  → Submission hook surfaces a form-level error

Network error
  → Submission hook surfaces a form-level error (or retry prompt)
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

Form library setup (default values, resolver, validation wiring) lives in the component by default. Extract it into its own hook when:

| Signal | Action |
|---|---|
| Defaults are computed from server data or user preferences | Extract `useItemFormConfig()` |
| Multiple components use the same form setup | Extract shared config hook |
| Static defaults, simple form | Inline in the component — no need to extract |

## Decision Guide

| Situation | Action |
|---|---|
| Form with an API call | Extract submission hook — always |
| Form with 2+ fields and validation | Schema in its own file, submission hook in its own file |
| Simple form (1–2 fields, no API call) | Inline everything in one component |
| Submit handler > 10 lines | Extract submission hook |
| Same form in multiple contexts | Ensure `onSuccess`/`onFailure` props, not hardcoded behavior |
| Need to test submission logic without rendering | Extract submission hook |
| Form needs computed defaults from server data | Extract configuration hook |
