# Commit Message Examples

## Good Examples by Type

### feat

```
feat(auth): add OAuth2 login with Google provider
```

```
feat: add dark mode toggle to settings page
```

```
feat(api): add pagination to user list endpoint

Support cursor-based pagination with configurable page size.
Default limit is 25, max is 100.

Closes #234
```

### fix

```
fix: prevent crash when user profile image is null
```

```
fix(router): resolve redirect loop on expired sessions
```

```
fix(csv-export): handle commas in quoted field values

The CSV parser was splitting on all commas including those inside
quoted strings. Now uses a proper state machine for parsing.

Closes #189
```

### refactor

```
refactor: extract validation logic into shared utility
```

```
refactor(db): replace raw SQL queries with query builder
```

```
refactor(components): convert class components to hooks

Migrates remaining class components to functional components
with hooks. No behavior changes — all existing tests pass.
```

### docs

```
docs: add API authentication guide to README
```

```
docs(contributing): clarify branch naming convention
```

### test

```
test: add integration tests for payment processing
```

```
test(auth): cover edge cases in token refresh logic
```

### build

```
build: upgrade typescript to 5.4
```

```
build(deps): replace moment with date-fns
```

### chore

```
chore: update .gitignore for new IDE config files
```

```
chore(release): bump version to 2.3.0
```

### perf

```
perf: lazy-load dashboard charts to reduce initial bundle
```

```
perf(search): add database index for full-text queries

Reduces search query time from ~800ms to ~50ms on the
production dataset.
```

### ci

```
ci: add Node 22 to test matrix
```

```
ci(deploy): switch staging deploys to OIDC authentication
```

### revert

```
revert: feat(api): add pagination to user list endpoint

Reverts commit a1b2c3d. The cursor-based pagination broke
the mobile client which expects offset-based pagination.
Will re-implement with backwards compatibility.
```

### style

```
style: apply prettier formatting to src/utils
```

```
style(lint): fix eslint warnings in test files
```

## Bad Examples with Corrections

### Too vague

```
# Bad
fix: fix bug

# Good
fix(cart): prevent negative quantity on item update
```

The description should say what was fixed, not just that something was fixed.

### Wrong type

```
# Bad
feat: fix login button alignment

# Good
style: fix login button alignment
```

A visual fix with no logic change is `style`, not `feat`. Choose the type that matches what actually changed.

### Not imperative mood

```
# Bad
feat: added search functionality

# Good
feat: add search functionality
```

Use imperative ("add") not past tense ("added") or present ("adds").

### Description too long

```
# Bad
refactor(auth): reorganize the authentication module to separate concerns between token management and session handling for better maintainability

# Good
refactor(auth): separate token management from session handling

Split the auth module into token-manager and session-store to
isolate concerns and simplify testing.
```

Keep the first line under 70 characters. Use the body for details.

### Mixing concerns

```
# Bad
feat(dashboard): add analytics widget and fix sidebar overflow

# Good (two separate commits)
fix(sidebar): prevent content overflow on narrow viewports
feat(dashboard): add analytics widget with weekly summary
```

One commit per concern. If "and" appears in your description, you likely need two commits.

### Missing type

```
# Bad
update dependencies

# Good
build(deps): update dependencies
```

The type prefix is required. `commitlint` will reject messages without one.

### Body explains "what" instead of "why"

```
# Bad
fix(parser): handle nested brackets

Changed the regex to support nested brackets by adding
a recursive pattern match on lines 45-60.

# Good
fix(parser): handle nested brackets

Template expressions like `${obj[arr[0]]}` were causing parse
errors because the bracket matcher didn't account for nesting.
```

The diff already shows *what* changed. The body should explain *why*.

### Capitalized description

```
# Bad
feat: Add user export feature

# Good
feat: add user export feature
```

Start the description with a lowercase letter.

## Scope Selection Guide

### When to use a scope

- The project has distinct modules, packages, or feature areas
- The scope helps a reader understand which part of the codebase changed
- Monorepo packages: use the package name (`feat(config-eslint): add rule`)

### When to omit scope

- The change is project-wide or cross-cutting
- The project is small with no clear module boundaries
- The scope would just repeat the type (`docs(docs): ...` — just use `docs:`)

### Common scope patterns

| Project type | Scope examples |
|---|---|
| Monorepo | Package names: `config-eslint`, `ui`, `api` |
| Web app | Feature areas: `auth`, `dashboard`, `settings` |
| API | Resource names: `users`, `orders`, `payments` |
| Library | Module names: `parser`, `validator`, `cli` |
| CLI tool | Command names: `init`, `build`, `deploy` |

### Scope consistency

Pick scope names and stick with them. Don't alternate between `auth`, `authentication`, and `login` for the same module. Check `git log --oneline` to see what scopes have been used before and follow the existing convention.
