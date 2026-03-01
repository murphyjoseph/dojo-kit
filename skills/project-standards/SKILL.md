---
name: project-standards
description: Hard rules for project hygiene. Use when installing dependencies,
  creating packages, naming files, setting up tooling, or making structural
  decisions about the codebase. These rules apply unconditionally.
---

# Project Standards

Non-negotiable rules that apply to every file, package, and dependency decision.

## Project Context

If `dojo-kit.yaml` exists at the project root, read it. Use `project.packageManager` for all install commands and lockfile references. The rules below are universal — only the specific commands (`pnpm add`, `npm install`, `yarn add`, `bun add`) and lockfile names adapt.

## Dependencies

| Rule | Rationale |
|---|---|
| Never install globally | Use `devDependencies` + `npx` for CLI tools. Global installs create "works on my machine" problems. |
| Use the project's package manager | Check the lockfile (`pnpm-lock.yaml`, `package-lock.json`, `yarn.lock`). Don't mix managers. |
| Pin major versions | Use `^` for minor/patch, never `*` or `latest` in `package.json`. |

## Packages

| Rule | Rationale |
|---|---|
| No "shared" packages | Name by function: `errors`, `logger`, `react-utils` — not `shared` or `common`. |
| Declare boundary via type | Each package declares whether it's `platform`, `react`, or `tooling` so consumers know the import cost. |
| Single responsibility | One package = one concern. Don't bundle unrelated utilities together. |
| No barrel files for re-export only | A file that only re-exports from other files adds indirection without value. Export directly from the source. |

## File Naming

| Rule | Example |
|---|---|
| Use kebab-case | `user-profile.ts`, `submit-order.factory.ts` |
| Never use underscores | `user_profile.ts` is wrong |
| Match exports to filenames | `useAuthToken.ts` exports `useAuthToken` |

## Commits

| Rule | Enforced by |
|---|---|
| Conventional Commits format | `commitlint` git hook — malformed messages are rejected |
| Format: `type(scope): description` | See `commit` skill for full guide |
| Never skip hooks | Don't use `--no-verify` |

## Security

| Rule | Rationale |
|---|---|
| Never commit secrets | No `.env` files, API keys, tokens, or credentials in version control |
| Validate at system boundaries | User input, external APIs — not between internal modules |
| Follow OWASP top 10 | No XSS, SQL injection, command injection in generated code |

## Structure

| Rule | Threshold |
|---|---|
| Flat structure | Fewer than 15 items in a directory |
| Namespaced subdirectories | 15+ items — group by function |
| Filenames use hyphens | `my-component.tsx`, not `MyComponent.tsx` or `my_component.tsx` |
