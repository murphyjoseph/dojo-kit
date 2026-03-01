---
name: data-flow
description: Error handling and API pipeline patterns. Use when writing functions
  that can fail, creating API integrations, handling server responses, designing
  error types, or deciding between throwing and returning errors.
---

# Data Flow

Functions that can fail return typed results. API operations follow a four-stage pipeline. Feature code never calls `fetch()` directly.

## Project Context

If `dojo-kit.yaml` exists at the project root, read it. Adapt the **Consume** stage examples to match `libraries.dataFetching`: `react-query` uses `useQuery`/`useMutation`, `swr` uses `useSWR`/`useSWRMutation`, `apollo` uses `useQuery`/`useMutation` from `@apollo/client`. If `libraries.validation` is set, use that library for request/response schemas in **Define** stage examples instead of the default `zod`. The Result type, error types, and Factory/Unpack stages are library-agnostic and do not change.

## Result Type

```typescript
type Result<T, E> =
  | { success: true; data: T }
  | { success: false; error: E };
```

All functions you write that can fail return `Result<T, E>`. The caller sees from the type that failure is possible and handles both paths explicitly.

## Throw vs Return

| Situation | Use | Why |
|---|---|---|
| Business logic failure | `Result` | Caller decides how to handle |
| Broken invariant (impossible state) | `throw` | Let error boundary catch it |
| Third-party code (`fetch`, `JSON.parse`) | `try/catch` at the boundary | Convert to `Result` immediately |

**The boundary rule:** `try/catch` wraps things that throw. Everything you write returns results. The boundary between thrown world and result world is thin, explicit, and low in the stack.

## Error Types

Two classes cover almost everything:

| Class | Fields | When to use |
|---|---|---|
| `ErrorBase` | `code`, `message`, `cause?`, `displayMessage?` | All errors |
| `ValidationError` | Extends ErrorBase + `fieldErrors: Record<string, string>` | Server-side field validation failures |

**Error code format:** `CONTEXT_ACTION_CAUSE` — e.g., `CHECKOUT_SUBMIT_VALIDATION_ERROR`, `USER_GET_CURRENT_NETWORK_ERROR`

Don't create `NetworkError`, `TimeoutError`, etc. Use `ErrorBase` with a specific code. The code is what consumers branch on.

## API Pipeline

Every API operation follows four stages:

| Stage | Responsibility | Testability |
|---|---|---|
| **Define** | Request shape (endpoint, document, types) — no logic | Type-checked at compile time |
| **Unpack** | Normalize every response variant into `Result` | Pure function — assert input → output |
| **Factory** | Wrap transport in `try/catch`, return typed operations | Mock the gateway, test with plain calls |
| **Consume** | Wire into framework (React Query hook, server loader) | Mock the factory |

**Gateway rule:** feature code never calls `fetch()` directly. A gateway handles request execution, auth injection, base URL resolution, and logging. Auth is middleware — feature code doesn't think about tokens.

## Decision Triggers

- **"How should this function handle failure?"** → consult `references/errors.md`
- **"How do I integrate a new API endpoint?"** → consult `references/api-pipeline.md`
- **"Should I throw or return?"** → return `Result` for your code, `try/catch` only at third-party boundaries

## References

- **`references/errors.md`** — Full error specification: `Result` type usage, `ErrorBase`/`ValidationError` definitions, error code conventions, error flow through system layers
- **`references/api-pipeline.md`** — API pipeline specification: define/unpack/factory/consume stages, gateway pattern, when to simplify
