---
name: commit
description: Guide for making good git commits with conventional commit messages.
  Use when committing code changes, writing commit messages, deciding when or how
  to commit, scoping changes for a commit, splitting work into multiple commits,
  or working with conventional commit format.
---

# Git Commit Guide

Create well-scoped commits with clear conventional commit messages. This project enforces conventional commit format via a `commitlint` git hook — malformed messages will be rejected at commit time.

## When to Commit

Commit when you reach a **logical checkpoint**:

- A feature, fix, or refactor is complete and working
- Tests pass for the changes you've made
- You're about to switch to a different concern (commit current work first)
- A meaningful intermediate milestone is reached during larger work

**Do not commit when:**

- Code is in a broken or half-finished state
- Tests are failing due to your changes
- You have unrelated changes mixed together (split them first)
- You're unsure what the changes accomplish (understand before committing)

## How to Scope Commits

Each commit should represent **one logical change**:

- **One concern per commit** — a bug fix, a feature addition, a refactor, a dependency update, etc.
- **Tests belong with the code they test** — don't separate implementation and test commits for the same feature
- **Refactors separate from behavior changes** — if you refactor code and then change behavior, those are two commits
- **Config changes get their own commit** — linter rules, tsconfig, CI changes are distinct from code changes
- **Split unrelated changes** — if you fixed a typo while implementing a feature, that's two commits

When changes are tangled, use `git add -p` or stage specific files to separate them into distinct commits.

## Commit Message Format

```
type(scope): description

[optional body]

[optional footer(s)]
```

### Type (required)

| Type | When to use |
|---|---|
| `feat` | New feature or capability for the user |
| `fix` | Bug fix |
| `docs` | Documentation only (README, comments, JSDoc) |
| `style` | Formatting, whitespace, semicolons — no logic change |
| `refactor` | Code restructuring with no behavior change |
| `perf` | Performance improvement with no behavior change |
| `test` | Adding or updating tests only |
| `build` | Build system, dependencies, package config |
| `ci` | CI/CD pipeline changes |
| `chore` | Maintenance tasks that don't fit other types |
| `revert` | Reverting a previous commit |

### Scope (optional)

A short noun identifying the area of change, in parentheses:

- In monorepos, use the package name: `feat(config-eslint): add rule`
- In apps, use the module or feature area: `fix(auth): handle expired tokens`
- Omit scope when the change is broad or the project is small

### Description (required)

- Use **imperative mood**: "add feature" not "added feature" or "adds feature"
- **Lowercase** first letter, no period at end
- Keep under **70 characters** (hard limit: 100)
- Describe **what** the commit does, not how

### Body (optional)

- Separate from description with a blank line
- Explain **why** the change was made and any important context
- Wrap at 100 characters per line
- Use when the description alone isn't sufficient

### Footer (optional)

- `BREAKING CHANGE: description` for breaking changes
- `Co-Authored-By: Name <email>` for co-authored commits
- `Refs: #123` or `Closes #456` for issue references

## Commit Workflow

Follow these steps when making a commit:

1. **Review changes** — run `git diff` (unstaged) and `git diff --staged` (staged) to understand what changed
2. **Assess scope** — determine if changes represent one concern or need splitting
3. **Stage files** — add specific files with `git add <file>` rather than `git add .` to avoid including unintended changes; never stage sensitive files (.env, credentials)
4. **Draft message** — choose the correct type and scope, write an imperative description
5. **Commit** — use a heredoc for multi-line messages to preserve formatting
6. **Verify** — run `git log --oneline -3` to confirm the commit looks right

Always let the `commitlint` hook validate your message — do not bypass it with `--no-verify`.

## References

- **`references/commit-message-examples.md`** — Good and bad examples for every commit type, common mistakes with corrections, and scope selection guidance. Read when unsure about message wording or format.
- **`references/advanced-patterns.md`** — Multi-file commits, breaking changes, reverts, co-authored commits, amend/fixup rules, and commit frequency heuristics. Read when dealing with complex commit scenarios.
