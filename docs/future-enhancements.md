# Future Enhancements

Ideas that came up during planning but are tabled for later.

## Skill Description Token Budget

Most well-crafted plugin skills keep their `description` frontmatter under 100 tokens. Several of ours exceed 150 tokens — `scaffolding`, `data-flow`, and `architecture` are the worst offenders. Verbose descriptions waste context on every skill-matching evaluation, even when the skill isn't invoked. Audit each skill's description and tighten to under 100 tokens while preserving trigger accuracy. Key technique: move "when to use" examples and edge-case triggers into the skill body (which is only loaded on invocation) and keep the description to a single sentence that captures the core purpose.

## Automatic Activity Logging

Claude maintains a running log of what it built/changed in `docs/activity/`. Could be automatic (hook on commit that prompts Claude to update the log) or on-demand. Risk: automatic means noise, on-demand means gaps. Needs experimentation.

## Project Docs Folder Convention

Each project gets a `docs/` folder (location configurable in `dojo-kit.yaml`) with sections:
- `features/` — what was built and how it works
- `decisions/` — ADR-style records of why choices were made
- `activity/` — running log of what Claude built/changed
- `prds/` — product requirements driving the work

The project-standards skill would enforce: document features when complete, log decisions when architectural choices are made.

## Backend Architecture Skills

Equivalent skills for server-side patterns — API design, database access patterns (Postgres, SQLite, Prisma vs Drizzle vs raw SQL), auth architecture, queue/job design. Framework-agnostic like the frontend ones. Would slot into the plugin as additional skills. Database structure choice (which DB, ORM vs query builder, migration strategy) could be detected by init and stored in `dojo-kit.yaml`.

## Linter Configuration from YAML

The init command detects ESLint or Biome but doesn't act on it. Future: `dojo-kit.yaml` declares the linter choice and the plugin provides a skill or reference that generates a recommended config based on detected dependencies (e.g., suggest `eslint-plugin-import` if using ESLint, or the equivalent Biome rules). Boundary-first import restrictions would be on by default with an opt-out in the YAML.

## Build-Time Boundary Enforcement

Generate ESLint `import/no-restricted-paths` rules (or Biome import restrictions, or tsconfig path restrictions) from the boundary-first architecture automatically. The init command could scaffold these based on the project structure. Referenced in the boundary doc as "something worth building." Ties into the linter configuration enhancement above — boundary enforcement is the highest-value generated rule.

## Vendored Skill Sync Strategy

`frontend-design` and `claude-md-improver` are vendored from Anthropic's official skills (Apache 2.0) into `skills/`. The `skills-lock.json` still references them as external sources. This creates two sources of truth — local copies will drift from upstream as Anthropic updates the originals. Need to decide: (a) fully own them locally and remove the `skills-lock.json` entries, or (b) remove local copies and rely on the marketplace, or (c) build a sync mechanism that pulls upstream changes and lets us merge/diff. Decision deferred until we see how often upstream changes and whether we need to customize the content.

## Framework-Specific Reference Files

Swap-in reference files per framework — e.g., Next.js App Router conventions vs TanStack Start conventions. The core skill stays generic, but a reference file provides framework-specific examples. Init could select the right ones based on `dojo-kit.yaml`.

## Configurable PR Template

The `skills/pull-request/assets/template.md` template is currently hardcoded into the PR skill. This should be surfaced as a configurable default — our template is the sensible default, but users should be able to swap in their own. The init command could ask whether to use the dojo-kit PR template or point to an existing one. The PR skill reads from wherever the config says the template lives.

## Configurable Commit Convention

The commit skill currently assumes Conventional Commits with commitlint. This should be a choice during init:
- Conventional Commits (our default, with commitlint hook)
- Another convention (surface alternatives — e.g., gitmoji, Angular, custom)
- No enforced convention

The commit skill adapts its guidance based on what was chosen. The commitlint hook is only installed if Conventional Commits is selected
## Planning & Thinking Skills

A set of skills focused on the *thinking* phase before code gets written:

- **Documentation** — a skill for writing high-quality feature docs, API docs, onboarding guides. Not just "add comments" but structured technical writing with audience awareness.
- **Feature planning** — helps think through a feature end-to-end: requirements, edge cases, affected boundaries, data flow. Produces a structured prompt/spec that goes to `docs/prompts/` (or `docs/prds/`) and can drive implementation.
- **Architecture review** — evaluates a proposed approach against the project's architecture philosophy. Surfaces boundary violations, coupling risks, missing error handling, over-engineering. Could run before implementation as a design review or after as a sanity check.

These are "meta" skills — they don't write code, they improve the quality of thinking that happens before and around the code. They'd output documents, not source files.

## Environment Variables Skill

A skill (or reference within project-standards) for managing environment variables:
- Detect the project's env var strategy (plain `.env`, framework-specific like Next.js `NEXT_PUBLIC_*`, or a secrets manager like Doppler/Infisical)
- Build-time validation — use Zod (or similar) to validate that all required env vars are present at startup, fail fast if not
- Never reference an env var without it being declared in the validation schema
- Framework-aware: Next.js has `NEXT_PUBLIC_` prefix rules, Vite has `VITE_`, Remix has server/client separation
- Init could detect the pattern and add `envStrategy` to `dojo-kit.yaml`

## Refactoring Auditor

A command or skill that evaluates a proposed refactor before execution:
- Computes blast radius — which files, features, and boundaries are affected
- Identifies coupling risks — will this change create new cross-boundary imports?
- Suggests a migration path — incremental steps vs big bang
- Could run as a pre-implementation check: "Before you refactor X, here's what will be affected"
- Pairs well with the architecture skill's boundary rules to flag violations early

## Workflow Behavior Configuration

Surface hook-like behavior choices in `dojo-kit.yaml` so users can declaratively configure Claude's workflow without writing hook scripts:
- `onEdit: lint` — run linting after file edits (current default)
- `onLintFail: fix | warn | block` — auto-fix lint errors, warn and continue, or block until fixed
- `commits: auto | prompt | manual` — Claude commits as it goes (`auto`), asks before each commit (`prompt`), or never commits on its own (`manual`, user handles all commits). The commit skill adapts its behavior accordingly — in `manual` mode it stages changes and drafts the message but stops short of running `git commit`
- These would generate the appropriate `hooks.json` entries during init rather than requiring manual hook authoring

## Library / Package Creation Skill

A skill for creating new internal packages in a monorepo. Goes beyond scaffolding — encodes preferences and dependency hygiene rules so Claude builds packages the right way every time.

### Build strategy (configurable in `dojo-kit.yaml`)
- **Pre-built** — package builds independently (tsup, Vite library mode, esbuild), exports compiled output. Consumed apps import the built artifact. Better isolation, faster app builds, clearer contract.
- **App-bundled** — package has no build step. The consuming app's bundler resolves and compiles the source directly. Simpler setup, tighter coupling, slower app builds at scale.
- Default preference stored in YAML, overridable per package.

### Package structure preferences
- Configurable directory layout in `dojo-kit.yaml` (e.g., `src/`, `tests/`, flat vs nested)
- Set up correct `exports`, `main`, `types` fields based on build strategy
- Wire into the workspace (add to workspace config, configure tsconfig paths)

### Naming conventions
- Configurable prefix convention in `dojo-kit.yaml` — e.g., `lib-`, `platform-`, `ui-`, `tooling-`
- Prefixes signal boundary type at a glance: `platform-logger`, `lib-validation`, `ui-form-fields`
- Enforce the project-standards rules: name by function (not "shared" or "common"), single responsibility

### Dependency hygiene
- **Framework contamination guard** — a package that could be vanilla JS/TS must not import React, Vue, or any framework. If it needs framework code, it belongs in a different boundary type (e.g., `ui-` not `lib-`).
- **No unnecessary third-party deps** — flag when a package pulls in a heavy dependency for trivial use. Prefer lightweight or zero-dep alternatives for utility packages.
- **Peer dependencies by default** — framework and shared runtime deps (React, a design system, etc.) should be `peerDependencies`, not `dependencies`. The consuming app owns the version.
- **Internal deps stay internal** — packages within the monorepo reference each other via workspace protocol (`workspace:*`), never published versions.
- These rules could be enforced via a PostToolUse hook or as guidance within the skill itself.

## Code Smell Reviewer

A command or skill that reviews code for common smells and anti-patterns:
- **Type casting audit** — flag `as` casts and suggest `satisfies` or stronger type definitions. The goal is types that are correct by construction, not patched with assertions.
- **General smell detection** — overly broad `any` types, unused variables, dead code paths, functions that do too much, deeply nested conditionals, magic numbers/strings
- **Framework-specific patterns** — React: missing dependency arrays, prop drilling that should be context, inline object/function creation in render. Next.js: client components that could be server components.
- Could run on-demand ("review this file/feature") or as a periodic sweep ("review everything changed in the last 5 commits")
- Output is a structured report with severity, file path, line reference, and suggested fix — not just warnings but actionable guidance

## MCP Server Recommendations from YAML

After reviewing `dojo-kit.yaml`, detect the project's stack and suggest relevant MCP servers:
- Database detected (Postgres, SQLite, etc.) → suggest a database MCP server for schema introspection and query assistance
- Design system or Figma references → suggest a Figma MCP server
- Specific cloud provider (AWS, Vercel, etc.) → suggest provider-specific MCP servers
- API-heavy project → suggest OpenAPI or GraphQL MCP servers for schema-aware assistance
- Present suggestions during init or as a follow-up command, with instructions for adding them to `.mcp.json`
- Don't auto-install — flag the opportunity and let the user decide

## Testing Philosophy

A skill that implements a pragmatic approach to testing. Likely needs somewhat different sections for backend vs frontend.

- **Frontend testing strategy** — what to test at each layer: presenters get unit tests (pure functions, easy to assert), controllers get integration tests (mock API, verify orchestration), views get light smoke tests via Testing Library (render, verify key elements), schemas get validation edge-case tests
- **Backend testing strategy** — route handler tests, service layer tests, database integration tests, contract tests for API boundaries
- **Test naming and organization** — colocated test files (already enforced by scaffolding), naming conventions for describe/it blocks, test data factories vs inline fixtures
- **What NOT to test** — type-level guarantees, framework internals, implementation details (don't test that `useState` was called)

## Accessibility (a11y) Patterns

Guidance for building accessible interfaces as a default, not an afterthought.

- **WCAG compliance** — which level to target (AA as default), how to verify during development
- **ARIA usage in forms** — proper labeling, error announcement, required field indication, form validation messages linked to fields via `aria-describedby`
- **Focus management** — modal focus traps, focus restoration after dialogs close, skip navigation links, logical tab order
- **Keyboard navigation** — all interactive elements reachable via keyboard, custom widgets implement appropriate keyboard patterns (arrow keys for menus, escape to close)
- **Screen reader testing** — recommended tools (VoiceOver, NVDA), common pitfalls (decorative images without empty alt, live regions for dynamic content)
- **Integration with ui-patterns** — forms skill should generate accessible markup by default, presenter contract should include accessibility-relevant flags

## State Management Guidance

Decision framework for choosing the right state location based on the configured library.

- **Server state** (React Query, SWR, Apollo) — data from APIs, cached and synchronized. The default for anything fetched. Already covered by data-flow skill but needs a "when to use" framing
- **Local state** (`useState`, `useReducer`) — component-scoped, ephemeral. Form field focus, dropdown open/closed, animation state
- **URL state** (search params, path params) — shareable, bookmarkable. Filters, pagination, active tab, search queries
- **Global state** (Zustand, Redux Toolkit, Jotai) — cross-component state that isn't server data. Auth status, theme, feature flags, shopping cart
- **Decision table** — given a piece of state, which bucket does it belong in? Based on: does it come from the server? Does it need to survive navigation? Do multiple components need it? Should a URL capture it?

## Error Boundaries

React error boundary placement strategy and integration with the Result type system.

- **Placement strategy** — route-level boundaries (catch entire page crashes), feature-level boundaries (isolate feature failures from the rest of the page), critical-component boundaries (wrap third-party widgets that might throw)
- **Fallback UI patterns** — full-page error (route-level), inline error with retry button (feature-level), graceful degradation (hide broken widget, show rest of page)
- **Recovery strategies** — retry rendering, reset component state, navigate away, refresh data
- **Integration with Result types** — Result types handle *expected* failures (API errors, validation). Error boundaries handle *unexpected* failures (render crashes, broken invariants). They are complementary, not overlapping. A component that receives a `Result` error should display an error state, not throw to the boundary

## Wire dojo-kit.yaml into More Skills

Currently only the architecture skill adapts examples to configured libraries (e.g., route examples match the detected router). The data-flow and ui-patterns skills should do the same.

- **data-flow** — gateway examples should use the configured `httpClient` (already being addressed). Query/mutation examples should match `dataFetching` library (partially done). Error handling examples should use the configured `validation` library for response schemas
- **ui-patterns** — form examples should use the configured `forms` library (react-hook-form vs formik vs @tanstack/react-form). Validation examples should use the configured `validation` library. View examples should use the configured `styling` approach and `ui` component library
- **scaffolding** — the orchestrator should pass library context to each skill it coordinates so generated code is immediately runnable with the project's actual dependencies
- **Implementation approach** — each skill's "Project Context" section should expand to read more fields from `dojo-kit.yaml` and adapt examples accordingly. The YAML schema already captures these libraries; the skills just need to use them