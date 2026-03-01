# Forms

How to structure forms so that validation, submission, and rendering are separate, testable concerns.

## Quick Reference

| Rule | Description |
|---|---|
| One schema is the validation truth | Nothing else validates — not the component, not the handler |
| Submission hook owns all side effects | API calls, error mapping, type conversion |
| The form doesn't decide what happens next | It fires `onSuccess`; the parent handles consequences |
| Split when complexity arrives | A one-field form doesn't need four files |

## The Four Concerns

### 1. Schema (Validation Truth)

One schema defines every field, every constraint, every error message. This is the single source of validation. Shared validators (phone, email, date) are reusable, but the composition — which fields and rules this form has — lives in one file.

```typescript
// features/signup/schemas/signup.schema.ts
import { z } from 'zod';
import { emailValidator, phoneValidator } from '@/shared/validators';

export const signupSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  email: emailValidator,
  phone: phoneValidator.optional(),
  acceptTerms: z.literal(true, {
    errorMap: () => ({ message: 'You must accept the terms' }),
  }),
});

export type SignupFormValues = z.infer<typeof signupSchema>;
```

**Testable without rendering:** pass an object, assert valid or invalid.

### 2. Configuration

Default values and schema wiring. Configuration, not logic. For simple forms, inline in the component. Extract when defaults are computed from server data or user preferences.

```typescript
// features/signup/hooks/useSignupFormConfig.ts
export function useSignupFormConfig(prefill?: Partial<SignupFormValues>) {
  return useForm<SignupFormValues>({
    resolver: zodResolver(signupSchema),
    defaultValues: {
      name: prefill?.name ?? '',
      email: prefill?.email ?? '',
      phone: prefill?.phone ?? '',
      acceptTerms: false,
    },
  });
}
```

### 3. Submission Hook

Owns every side effect. Calls the API, reads the result, maps errors, type-converts values. Returns a submit handler and error state. Nothing else in the form has side effects.

```typescript
// features/signup/hooks/useSignupSubmit.ts
export function useSignupSubmit(form: UseFormReturn<SignupFormValues>) {
  const signup = useSignup(); // API factory hook
  const [formError, setFormError] = useState<string | null>(null);

  const onSubmit = async (values: SignupFormValues) => {
    setFormError(null);
    const result = await signup(values);

    if (!result.success) {
      if (result.error instanceof ValidationError) {
        // Map server field errors to form fields
        for (const [field, message] of Object.entries(result.error.fieldErrors)) {
          form.setError(field as keyof SignupFormValues, { message });
        }
        return;
      }
      // Unexpected error → form-level banner
      setFormError(result.error.displayMessage ?? 'Something went wrong');
      return;
    }

    // Success — don't navigate or track here
    return result.data;
  };

  return { onSubmit: form.handleSubmit(onSubmit), formError };
}
```

**Testable without UI:** mock the API, call the hook, assert error mapping.

### 4. Component

Composes fields and wires the hook. Doesn't validate, fetch, transform, or decide post-submission behavior.

```typescript
// features/signup/components/SignupForm.tsx
interface SignupFormProps {
  onSuccess: (user: User) => void;
  onFailure?: (error: ErrorBase) => void;
  prefill?: Partial<SignupFormValues>;
}

export function SignupForm({ onSuccess, onFailure, prefill }: SignupFormProps) {
  const form = useSignupFormConfig(prefill);
  const { onSubmit, formError } = useSignupSubmit(form);

  return (
    <Form {...form}>
      {formError && <FormBanner message={formError} />}
      <FormField name="name" label="Name" />
      <FormField name="email" label="Email" type="email" />
      <FormField name="phone" label="Phone" />
      <FormField name="acceptTerms" label="I accept the terms" type="checkbox" />
      <SubmitButton>Sign Up</SubmitButton>
    </Form>
  );
}
```

## Error Flow

```
Client-side validation fails
  → Schema error messages appear on fields

Server-side validation fails
  → Hook maps fieldErrors from Result to form.setError()

Unexpected server error
  → Hook sets form-level error banner

Network error
  → Hook sets form-level error banner (or retry prompt)
```

Each error type has exactly one handler. No ambiguity about which layer handles which kind of failure.

## The Form Doesn't Decide What Happens Next

The form fires callbacks. The parent handles consequences.

```typescript
// Page — decides navigation, tracking, toasts
function SignupPage() {
  const router = useRouter();

  const handleSuccess = (user: User) => {
    trackEvent('SIGNUP_COMPLETED');
    router.push('/dashboard');
  };

  return <SignupForm onSuccess={handleSuccess} />;
}
```

This means the same form works in a full page, a modal, a multi-step flow, or a settings panel — without changes.

## Decision Guide

| Situation | Action |
|---|---|
| Simple form (1–2 fields, no server validation) | Inline everything in one component |
| Submit handler > 15 lines | Extract submission hook |
| Validation rules shared across forms | Extract shared validators, compose in schema |
| Same form in multiple contexts | Ensure `onSuccess`/`onFailure` props, not hardcoded navigation |
| Need to test submission logic without rendering | Extract submission hook |
| Form needs computed defaults | Extract configuration hook |
