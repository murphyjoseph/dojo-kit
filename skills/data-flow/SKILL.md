---
name: data-flow
description: Error handling and API pipeline patterns. Use when creating any
  feature, page, or component that calls an API — including forms that submit
  data, pages that fetch and display data, or any code that talks to a server.
  Also use when writing functions that can fail, handling server responses,
  designing error types, or deciding between throwing and returning errors.
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

### REST APIs (default)

Most web apps use REST with straightforward JSON responses. Use a simple three-file pattern:

| File | Role | Example |
|---|---|---|
| `.api.ts` | Gateway functions — typed fetch wrappers | `items.api.ts` |
| `.queries.ts` | React Query query hooks (grouped per domain) | `items.queries.ts` |
| `.mutations.ts` | React Query mutation hooks (grouped per domain) | `items.mutations.ts` |

**Gateway rule:** feature code never calls `fetch()` directly. The `.api.ts` file handles request execution, auth injection, base URL, and logging. Auth is middleware — feature code doesn't think about tokens.

### Expected Files for a REST API Integration

All API files colocate in the feature's `api/` directory — gateway, queries, and mutations together:

```
features/<domain>/api/
  <domain>.api.ts                    ← Gateway functions (all endpoints for this domain)
  <domain>.queries.ts                ← React Query query hooks: useItems, useSearchItems, etc.
  <domain>.mutations.ts              ← React Query mutation hooks: useCreateItem, useUpdateItem, etc.
```

API files promote from `features/<domain>/api/` to `platform/api/` only when multiple features need the same endpoints. Until then, keep them feature-scoped.

### Complex APIs (GraphQL, polymorphic responses)

When response shapes are polymorphic or need explicit discrimination (GraphQL with partial errors, REST endpoints that return different shapes per status code), add an unpack stage:

| Stage | Responsibility | Testability |
|---|---|---|
| **Define** | Request shape (endpoint, document, types) — no logic | Type-checked at compile time |
| **Unpack** | Normalize every response variant into `Result` | Pure function — assert input → output |
| **Factory** | Wrap transport in `try/catch`, return typed operations | Mock the gateway, test with plain calls |
| **Consume** | Wire into framework (React Query hook, server loader) | Mock the factory |

Consult `references/api-pipeline.md` for the full four-stage pipeline specification. Use it when you copy-paste an API call, or a response shape change breaks something because the discrimination wasn't explicit.

## Decision Triggers

- **"How should this function handle failure?"** → consult `references/errors.md`
- **"How do I integrate a new API endpoint?"** → consult `references/api-pipeline.md`
- **"Should I throw or return?"** → return `Result` for your code, `try/catch` only at third-party boundaries

## References

- **`references/errors.md`** — Full error specification: `Result` type usage, `ErrorBase`/`ValidationError` definitions, error code conventions, error flow through system layers
- **`references/api-pipeline.md`** — API pipeline specification: define/unpack/factory/consume stages, gateway pattern, when to simplify
