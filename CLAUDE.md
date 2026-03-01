# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

dojo-kit is a **Claude Code plugin** — a web-focused drop-in toolkit providing architecture skills, project standards, and workflow automation. The repo root IS the plugin. Install it with `claude --plugin-dir <path-to-dojo-kit>` or add it to your project's plugin configuration.

## Repository Structure

```
.claude-plugin/plugin.json  — Plugin manifest
skills/                     — Plugin skills (8 total)
commands/                   — Slash commands
hooks/hooks.json            — Hook definitions
scripts/                    — Hook scripts
docs/references/            — Shared reference documents
.mcp.json                   — MCP server config (context7)
.lsp.json                   — LSP config (TypeScript)
eslint.config.js            — ESLint flat config (JS/TS/JSX/TSX)
```

### Skills

| Skill | Purpose |
|---|---|
| `architecture` | Boundary-first architecture and service patterns — import hierarchy, layer rules, promotion criteria |
| `data-flow` | Error handling (Result types) and API pipeline (define/unpack/factory/consume) |
| `ui-patterns` | Form architecture (schema/config/hook/component) and feature/view separation |
| `frontend-design` | Distinctive, production-grade UI — bold aesthetics, typography, color, motion, spatial composition |
| `project-standards` | Hard rules — no global installs, kebab-case files, conventional commits, no barrel files |
| `scaffolding` | Orchestrates feature scaffolding — coordinates architecture, ui-patterns, data-flow, and project-standards |
| `planning` | Plan before building — auto-generate plan documents for multi-file work, wait for approval |
| `claude-md-improver` | Audit and improve CLAUDE.md files — quality scoring, targeted updates, templates |

### Commands

| Command | Purpose |
|---|---|
| `dojo-kit-init` | Scan repo, detect stack, generate `dojo-kit.yaml` configuration |

## Linting

ESLint is configured in `eslint.config.js` (flat config with TypeScript support):

- `pnpm exec eslint <file>` — Lint a file
- `pnpm exec eslint .` — Lint the entire project

## Hooks

Hooks are defined in `hooks/hooks.json` and provided by the plugin:

- **PreToolUse → Conventional Commits** (prompt hook): Validates that `git commit` messages follow Conventional Commits format before execution.
- **PreToolUse → Colocation Enforcer** (prompt hook): Blocks file writes to type-based directories (`hooks/`, `components/`, `schemas/`, `presenters/`) inside `features/`. Redirects to concern-based colocation.
- **PostToolUse → lint-on-edit** (command hook): Auto-lints `.js/.ts/.jsx/.tsx` files after Write/Edit. Lint failures inform Claude via `systemMessage` but never block.
- **Notification → notify-sound** (command hook): Plays macOS `Tink.aiff` on notifications.

## Key Conventions

**Skill architecture** follows progressive disclosure: metadata (frontmatter) → SKILL.md (concise rules) → references/ (detailed specs). Keep SKILL.md concise to minimize context window usage; put detailed specifications in reference files.

**Command naming** uses verb-noun pattern (e.g., `dojo-kit-init`). Commands use YAML frontmatter for metadata and should specify the most restrictive `allowed-tools` possible.

**Hooks** prefer prompt-based hooks for context-aware logic and command-based hooks for deterministic checks. Command hooks use JSON I/O with exit codes: 0 = success, 2 = blocking error.

**Commit messages** follow [Conventional Commits](https://www.conventionalcommits.org/). Format: `type(scope): description`. Allowed types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`. A `commit-msg` git hook enforces this via `commitlint`.

**File organization** uses flat structure for <15 items and namespaced subdirectories for 15+. Filenames use hyphens, not underscores.
