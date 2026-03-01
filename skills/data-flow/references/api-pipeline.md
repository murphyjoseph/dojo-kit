# The API Pipeline

How to structure API operations so that transport, response discrimination, and consumption are separate, testable concerns.

## Quick Reference

| Rule | Description |
|---|---|
| Four stages | Define → Unpack → Factory → Consume |
| Gateway abstracts transport | Feature code never calls `fetch()` directly |
| Every response variant is handled | Unpack includes a catch-all for unknown shapes |
| Factory is the throw/result boundary | One `try/catch` converts network errors to `Result` |

## Pipeline Stages

### Stage 1: Define

Declare the request shape. This is the only place protocol-specific details live. Typed, static, no logic.

```typescript
// features/checkout/api/submit-order.definition.ts
export const submitOrderDef = {
  method: 'POST' as const,
  path: '/api/orders',
  body: z.object({
    items: z.array(orderItemSchema),
    paymentMethodId: z.string(),
  }),
  response: submitOrderResponseSchema,
};
```

**What belongs here:** endpoint path, HTTP method, request/response schemas, GraphQL documents
**What doesn't:** logic, error handling, auth, headers

### Stage 2: Unpack

Normalize every possible response variant into a `Result`. Handle every case explicitly. The catch-all at the end always returns a failure for unknown variants.

```typescript
// features/checkout/api/submit-order.unpack.ts
export function unpackSubmitOrder(
  response: SubmitOrderResponse
): Result<Order, ErrorBase | ValidationError> {
  if (response.status === 'success') {
    return success(response.data);
  }

  if (response.status === 'validation_error') {
    return failure(new ValidationError({
      code: 'CHECKOUT_SUBMIT_VALIDATION_ERROR',
      message: 'Order validation failed',
      fieldErrors: response.errors,
    }));
  }

  if (response.status === 'payment_declined') {
    return failure(new ErrorBase({
      code: 'CHECKOUT_SUBMIT_PAYMENT_DECLINED',
      message: response.message,
      displayMessage: 'Payment was declined. Please try a different method.',
    }));
  }

  // Catch-all — unknown variant
  return failure(new ErrorBase({
    code: 'CHECKOUT_SUBMIT_UNHANDLED',
    message: `Unknown response status: ${response.status}`,
  }));
}
```

**Key rule:** the catch-all is always present. When the backend adds a new variant you haven't handled, it surfaces immediately as an `UNHANDLED` error instead of silently succeeding with missing data.

### Stage 3: Factory

Takes a gateway (transport layer) and returns typed operations. Wraps transport calls in `try/catch` to convert thrown network errors into `Result`. From this point on, nothing throws.

```typescript
// features/checkout/api/submit-order.factory.ts
export function createSubmitOrder(gateway: Gateway) {
  return async (
    input: SubmitOrderInput
  ): Promise<Result<Order, ErrorBase | ValidationError>> => {
    try {
      const response = await gateway.post(
        submitOrderDef.path,
        input
      );
      return unpackSubmitOrder(response);
    } catch (error) {
      return failure(new ErrorBase({
        code: 'CHECKOUT_SUBMIT_NETWORK_ERROR',
        message: 'Network request failed',
        cause: error instanceof Error ? error : undefined,
      }));
    }
  };
}
```

**Testability:** mock the gateway, call the factory function, assert the `Result`. No HTTP, no DOM, no framework.

### Stage 4: Consume

Wire the factory into the framework. The consumer doesn't know or care about transport.

```typescript
// features/checkout/submit-order/use-submit-order.ts
export function useSubmitOrder() {
  const gateway = useGateway();
  const submitOrder = createSubmitOrder(gateway);

  return useMutation({
    mutationFn: submitOrder,
  });
}
```

## The Gateway

Feature code never calls `fetch()`. A gateway abstraction handles:

| Concern | Handled by |
|---|---|
| Request execution | Gateway core |
| Auth token injection | Middleware |
| Base URL resolution | Configuration |
| Request/response logging | Middleware |
| Headers (content-type, etc.) | Middleware |

```typescript
// platform/api/gateway.ts
export function createGateway(config: GatewayConfig): Gateway {
  return {
    async get<T>(path: string): Promise<T> {
      const response = await fetch(`${config.baseUrl}${path}`, {
        headers: config.getHeaders(),
      });
      return response.json();
    },
    async post<T>(path: string, body: unknown): Promise<T> {
      const response = await fetch(`${config.baseUrl}${path}`, {
        method: 'POST',
        headers: config.getHeaders(),
        body: JSON.stringify(body),
      });
      return response.json();
    },
  };
}
```

**Auth is middleware, not feature code.** The gateway injects tokens. If the auth strategy changes, update the middleware — not every API call.

## When to Simplify

Not every API call needs four files. The full pipeline manages complexity that comes with scale.

| Situation | Approach |
|---|---|
| Prototype or weekend project | Inline `fetch()` is fine |
| Single unreused API call | Combine define + unpack into one file |
| Copy-pasting an API call | Time to introduce the pipeline |
| Response shape change broke something | Time to make discrimination explicit |

**Signal to introduce the pipeline:** the moment you copy an API call, or a response shape change breaks something because the discrimination wasn't explicit.

## Decision Guide

| Situation | Action |
|---|---|
| New API endpoint | Create define → unpack → factory → consumer |
| Backend adds a response variant | Update the unpack function, add a test case |
| Switching HTTP clients | Change the gateway, consumers are untouched |
| Adding retry logic | Add to the gateway or factory, consumers are untouched |
| Testing API logic | Mock the gateway, call the factory directly |
| Testing UI with API data | Mock the factory, pass `Result` values to the hook |
