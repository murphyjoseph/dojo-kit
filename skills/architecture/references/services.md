# Services

How to structure cross-cutting concerns (logging, analytics, feature flags) so that feature code depends on a stable interface, not a vendor.

## Quick Reference

| Rule | Description |
|---|---|
| Three-step lifecycle | Create → Initialize → Use |
| Feature code sees only the interface | `logger.info()`, not `datadogLogs.logger.info()` |
| Environment-aware initialization | Browser, server, and edge each get their own init |
| Explicit initialization order | Bootstrap step calls services in dependency order |

## Lifecycle Specification

### Step 1: Create

Create the singleton instance with base configuration. Register universal handlers (e.g., console logging). Runs once at startup.

```typescript
// platform/logger/create.ts
export function createLogger(config: LoggerConfig): Logger {
  const logger = new Logger(config);
  logger.addHandler(consoleHandler);
  return logger;
}
```

### Step 2: Initialize (per environment)

Register environment-specific handlers. Each environment gets its own init function. Feature code never sees this.

```typescript
// platform/logger/init-browser.ts
export function initBrowserLogger(logger: Logger) {
  logger.addHandler(datadogBrowserHandler);
}

// platform/logger/init-server.ts
export function initServerLogger(logger: Logger) {
  logger.addHandler(datadogServerHandler);
}
```

### Step 3: Use

The public interface. The only thing feature code imports. Stable contract, swappable implementation.

```typescript
// In any feature file
import { logger } from '@/platform/logger';

logger.info('User signed up', { feature: 'onboarding' });
```

## Initialization Order

Services depend on each other. Make the order explicit in a bootstrap step.

```typescript
// platform/bootstrap.ts
export async function bootstrap(env: Environment) {
  const config = createAppConfig();
  const logger = createLogger(config);
  const analytics = createAnalytics({ logger });
  const flags = createFeatureFlags({ logger, config });

  if (env === 'browser') {
    initBrowserLogger(logger);
    initBrowserAnalytics(analytics);
  }

  if (env === 'server') {
    initServerLogger(logger);
    initServerAnalytics(analytics);
  }
}
```

**Guard against double initialization** — use a state flag so bootstrap runs exactly once, even in development mode, strict mode double-rendering, or serverless cold starts.

## What Qualifies as a Service

A service is a cross-cutting concern with all three properties:

| Property | Test |
|---|---|
| Feature code uses it but doesn't own it | Used by many features, owned by none |
| Environmental differences | Implementation changes between browser/server/edge/test |
| Wraps a vendor | Vendor API hidden behind a stable interface |

### Not services

| Thing | Why not | Where it belongs |
|---|---|---|
| REST client | Transport infrastructure, not cross-cutting | `platform/api/` |
| Date formatting | Pure utility, no environment differences | `shared/utils/` |
| Auth middleware | Request-level concern, no vendor wrapping | `platform/auth/` or middleware |

## Structured Logging Convention

| Field | Required | Description |
|---|---|---|
| `level` | Yes | `debug`, `info`, `warn`, `error` |
| `message` | Yes | Human-readable description |
| `feature` | Yes | Which feature produced the log |
| `metadata` | No | Structured key-value context |

**Rules:**
- Never log PII (names, emails, phone numbers, addresses)
- Analytics event names are constants, not inline strings — searchable via a dictionary, not grep across features

## Decision Guide

| Situation | Action |
|---|---|
| Need logging in a feature | Import from `platform/logger`, never import vendor SDK directly |
| Adding a new vendor (e.g., Sentry) | Create a handler, register it in the environment-specific init |
| Swapping a vendor | Change the handler implementation, interface stays the same |
| Writing tests | Skip initialization — service works with no handlers (or a test handler) |
| New cross-cutting concern | Check the three qualifications above. If all three apply, build as a service. |
