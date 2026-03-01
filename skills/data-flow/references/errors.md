# Errors as Data

How to handle errors so that failure paths are typed, explicit, and testable — not hidden in exception control flow.

## Quick Reference

| Rule | Description |
|---|---|
| Functions return `Result<T, E>` | Callers see failure is possible from the type signature |
| `try/catch` only at boundaries | Wrap third-party code that throws, convert to `Result` immediately |
| Two error classes | `ErrorBase` for everything, `ValidationError` for field-level server errors |
| Error codes are machine-readable | Format: `CONTEXT_ACTION_CAUSE` |

## Result Type Specification

```typescript
type Result<T, E> =
  | { success: true; data: T }
  | { success: false; error: E };

// Helper constructors
function success<T>(data: T): Result<T, never> {
  return { success: true, data };
}

function failure<E>(error: E): Result<never, E> {
  return { success: false, error };
}
```

### Usage

```typescript
function getUser(id: string): Result<User, ErrorBase> {
  const user = userStore.get(id);
  if (!user) {
    return failure(new ErrorBase({
      code: 'USER_GET_NOT_FOUND',
      message: `User ${id} not found`,
    }));
  }
  return success(user);
}

// Caller — both paths are explicit
const result = getUser(id);
if (!result.success) {
  // handle result.error
  return;
}
// use result.data
```

## When to Throw vs Return

| Scenario | Use | Example |
|---|---|---|
| Function can fail in expected ways | `Result` | User not found, validation failed |
| Broken invariant (impossible state) | `throw` | Required URL param missing from guaranteed route |
| Third-party code | `try/catch` → `Result` | `fetch()`, `JSON.parse()`, browser APIs |

**Boundary rule:** one `try/catch` in the API factory converts thrown errors to `Result`. From that point up, nothing throws.

## Error Class Definitions

### ErrorBase

```typescript
class ErrorBase extends Error {
  readonly code: string;
  readonly cause?: Error;
  readonly displayMessage?: string;

  constructor(params: {
    code: string;
    message: string;
    cause?: Error;
    displayMessage?: string;
  }) {
    super(params.message);
    this.code = params.code;
    this.cause = params.cause;
    this.displayMessage = params.displayMessage;
  }
}
```

| Field | Purpose |
|---|---|
| `code` | Machine-readable, for branching logic |
| `message` | Human-readable, for logs |
| `cause` | Original error, for debugging |
| `displayMessage` | UI-safe message, when appropriate |

### ValidationError

```typescript
class ValidationError extends ErrorBase {
  readonly fieldErrors: Record<string, string>;

  constructor(params: {
    code: string;
    message: string;
    fieldErrors: Record<string, string>;
    cause?: Error;
    displayMessage?: string;
  }) {
    super(params);
    this.fieldErrors = params.fieldErrors;
  }
}
```

Use exclusively for server-side validation failures where the backend reports which fields are wrong.

## Error Code Convention

Format: `CONTEXT_ACTION_CAUSE`

```
CHECKOUT_SUBMIT_VALIDATION_ERROR
USER_GET_CURRENT_NETWORK_ERROR
CART_UPDATE_UNHANDLED
AUTH_REFRESH_TOKEN_EXPIRED
```

- **Domain:** feature or module name
- **Operation:** what was attempted
- **Variant:** what went wrong

Don't create separate error classes (`NetworkError`, `TimeoutError`). Use `ErrorBase` with a specific code. The code is what consumers branch on, not the class.

## Error Flow Through the System

```
API Response
  → Unpack layer (discriminates response variants → Result)
    → Factory (try/catch converts network throws → Result)
      → Consumer hook/controller (maps errors to UI state)
        → View (renders pre-computed flags, never inspects error codes)
```

### Each layer's responsibility

| Layer | Does | Does not |
|---|---|---|
| Unpack | Converts every response variant to `Result` | Throw, touch UI state |
| Factory | Wraps transport in `try/catch`, returns `Result` | Know about UI, decide what to display |
| Consumer | Maps `ValidationError` → field errors, `ErrorBase` → banner | Call `fetch()`, inspect response shapes |
| View | Renders `showError`, `errorMessage` flags | Inspect error codes, make decisions about what went wrong |

## Decision Guide

| Situation | Action |
|---|---|
| Writing a function that can fail | Return `Result<T, E>` |
| Wrapping a `fetch()` call | `try/catch` → `failure(new ErrorBase(...))` |
| Server returns field-level errors | Create `ValidationError` with `fieldErrors` map |
| Need a new error type | Use `ErrorBase` with a specific code — don't create a new class |
| Error needs to reach the UI | Set `displayMessage` on `ErrorBase`, or map in consumer layer |
| Impossible state reached | `throw` — let error boundary catch it |
