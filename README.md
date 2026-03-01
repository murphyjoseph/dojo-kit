# dojo-kit

A web-focused drop-in plugin for Claude Code — architecture skills, project standards, and workflow automation.

## What is dojo-kit?

dojo-kit is a [Claude Code plugin](https://docs.anthropic.com/en/docs/claude-code). It teaches Claude how to structure web projects by providing opinionated skills for architecture, data flow, UI patterns, and day-to-day workflows like commits and PRs. No code generation — just well-written guidance that Claude reads and follows in context.

> **Note:** dojo-kit is currently built around the JavaScript/TypeScript/Node ecosystem. The architecture and workflow skills (commits, PRs, project standards) are language-agnostic, but the data-flow, UI, and package patterns assume JS/TS tooling. Support for other ecosystems (Python, Go, etc.) is not yet in scope.

## Install

```bash
claude plugin add /path/to/dojo-kit
```

Or add it to a project's `.claude/plugins.json`:

```json
["/path/to/dojo-kit"]
```

### Requirements

- Node >= 24
- pnpm >= 10

After cloning, run `pnpm install` to set up commitlint, ESLint, and git hooks.

## What's included

### Skills

Seven skills activate automatically based on what you're doing:

| Skill | What it teaches Claude |
| --- | --- |
| **architecture** | Boundary-first layer system (`app/ → features/ → shared/ → platform/`), import hierarchy, promotion criteria, cross-cutting service patterns |
| **data-flow** | `Result<T, E>` error handling, throw vs return boundaries, typed API pipeline (define → unpack → factory → consume) |
| **ui-patterns** | Form architecture (schema / config / hook / component), feature/view separation (orchestrate / present / render) |
| **frontend-design** | Distinctive, production-grade UI design — bold aesthetic direction, typography, color, motion, spatial composition. Avoids generic AI aesthetics |
| **project-standards** | Hard rules — no global installs, kebab-case files, conventional commits, no barrel files, OWASP compliance |
| **commit** | When to commit, how to scope changes, conventional commit message format |
| **pull-request** | PR scoping, template population, `gh pr create` workflow |

Each skill follows progressive disclosure: a concise `SKILL.md` stays in context, with detailed `references/` loaded only when needed.

### Command

**`/dojo-kit-init`** — Scans your project (framework, libraries, monorepo structure) and generates a `dojo-kit.yaml` config file. Asks about anything it can't infer.

### Hooks

| Hook | Trigger | What it does |
| --- | --- | --- |
| Conventional Commits | PreToolUse (Bash) | Validates `git commit` messages against Conventional Commits format before execution |
| lint-on-edit | PostToolUse (Write/Edit) | Runs ESLint on `.js/.ts/.jsx/.tsx` files after edits; reports errors to Claude without blocking |
| notify-sound | Notification | Plays macOS Tink sound on notifications |

### Bundled configs

- **MCP** — [Context7](https://github.com/upstash/context7) for up-to-date library documentation
- **LSP** — TypeScript Language Server for JS/TS/JSX/TSX
- **ESLint** — Flat config with TypeScript support
- **commitlint** — Conventional Commits enforcement via git hook

## Project structure

```
.claude-plugin/plugin.json   Plugin manifest
skills/                      6 skills with reference docs
commands/                    Slash commands
hooks/hooks.json             Hook definitions
scripts/                     Hook and git hook scripts
docs/references/             Shared reference documents
docs/decisions/              Architecture decision records
```

## Acknowledgments

The `frontend-design` skill is adapted from [Anthropic's Claude Code](https://claude.ai/code) default skills, licensed under Apache 2.0.

## License

MIT
