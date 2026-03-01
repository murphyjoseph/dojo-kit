# dojo-kit

A web-focused drop-in plugin for Claude Code — architecture skills, project standards, and workflow automation.

## What is dojo-kit?

dojo-kit is a [Claude Code plugin](https://docs.anthropic.com/en/docs/claude-code). It teaches Claude how to structure web projects by providing opinionated skills for architecture, data flow, UI patterns, and project standards. No code generation — just well-written guidance that Claude reads and follows in context.

> **Note:** dojo-kit is currently optimized for **frontend** web development in the JavaScript/TypeScript/Node ecosystem. The architecture, data-flow, and UI skills target React-based SPAs and SSR frameworks (Next.js, Remix, Vite). Workflow skills (project standards, planning) are language-agnostic. **Backend-specific patterns** (API design, database layers, queue workers) are on the roadmap but not yet included.

## Getting started

### 1. Add dojo-kit to your project

Add a `.claude/settings.json` to your project root:

```json
{
  "extraKnownMarketplaces": {
    "codedojoe": {
      "source": {
        "source": "github",
        "repo": "codedojoe/claude-plugins"
      }
    }
  },
  "enabledPlugins": {
    "dojo-kit@codedojoe": true
  }
}
```

Commit this file. Claude Code will download and install dojo-kit automatically — no cloning required. Teammates who clone your project get the same setup when they trust the project settings.

### 2. Run init

Start a Claude Code session in your project and run:

```
/dojo-kit-init
```

This does three things:

1. **Scans your project** — detects framework, libraries, monorepo structure
2. **Generates config** — creates `dojo-kit.yaml` and injects architecture rules into your `CLAUDE.md`
3. **Offers companion tools** — recommends third-party plugins and tools that work well with dojo-kit

### Companion tools

During init, you'll be asked which companion tools to install. These are **not part of dojo-kit** — they're third-party tools that complement it:

| Companion | Author | What it provides |
|---|---|---|
| `superpowers` | Anthropic | Brainstorming, TDD, plan execution, code review workflows |
| `frontend-design` | Anthropic | Production-grade UI design — typography, color, motion, spatial composition |
| `context7` | Upstash | Up-to-date library documentation via MCP |
| `typescript-lsp` | — | TypeScript/JavaScript language server for diagnostics |

All optional. Your choices are recorded in `dojo-kit.yaml` so re-running init won't re-ask.

## Contributing

To develop or customize dojo-kit itself:

```bash
git clone https://github.com/murphyjoseph/dojo-kit.git
cd dojo-kit
pnpm install   # sets up commitlint, ESLint, git hooks
```

Test your changes locally by pointing Claude Code at your clone:

```bash
cd /path/to/your-project
claude --plugin-dir /path/to/dojo-kit
```

## What's included

### Skills

Seven skills activate automatically based on what you're doing:

| Skill | What it teaches Claude |
| --- | --- |
| **scaffolding** | Orchestrates architecture, UI, and data-flow patterns when building new features — file naming conventions, concern-based colocation, expected file listings |
| **architecture** | Boundary-first layer system (`routes → features/ → shared/ → platform/`), import hierarchy, promotion criteria, cross-cutting service patterns |
| **data-flow** | `Result<T, E>` error handling, throw vs return boundaries, REST API pattern (gateway + queries + mutations), full pipeline for GraphQL |
| **ui-patterns** | Form architecture (`.schema.ts` / `.controller.ts` / `.view.tsx`), feature/view separation (controller / presenter / view) |
| **project-standards** | Hard rules — no global installs, kebab-case files, conventional commits, no barrel files, OWASP compliance |
| **planning** | Auto-generate a plan document before multi-file work — scope, architecture impact, file breakdown, implementation order |
| **claude-md-improver** | Audit, evaluate, and improve CLAUDE.md files — quality scoring, targeted updates, templates by project type |

Each skill follows progressive disclosure: a concise `SKILL.md` stays in context, with detailed `references/` loaded only when needed.

### File naming conventions

dojo-kit enforces functional suffixes so every file's role is clear from its name:

| Suffix | Role | Example |
|---|---|---|
| `.api.ts` | Gateway functions (fetch wrappers) | `items.api.ts` |
| `.queries.ts` | Query hooks (grouped per domain) | `items.queries.ts` |
| `.mutations.ts` | Mutation hooks (grouped per domain) | `items.mutations.ts` |
| `.schema.ts` | Zod validation schema | `item-form.schema.ts` |
| `.controller.ts` | Logic hook — submission (forms) or orchestration (features) | `item-form.controller.ts` |
| `.presenter.ts` | Pure function: raw data → view contract | `dashboard.presenter.ts` |
| `.view.tsx` | Thin render component | `item-form.view.tsx` |

### Feature structure

Files are organized by concern, not type. No `hooks/`, `components/`, `schemas/`, or `presenters/` directories inside features:

```
features/items/
  types.ts
  api/
    items.api.ts
    items.queries.ts
    items.mutations.ts
  create-item/
    item-form.schema.ts
    item-form.controller.ts
    item-form.view.tsx
  search/
    search.controller.ts
    search.presenter.ts
    search.view.tsx
```

### Command

**`/dojo-kit-init`** — Scans your project, generates `dojo-kit.yaml`, injects architecture rules into `CLAUDE.md`, and offers companion tool installation.

### Hooks

| Hook | Trigger | What it does |
| --- | --- | --- |
| Conventional Commits | PreToolUse (Bash) | Validates `git commit` messages against Conventional Commits format before execution |
| Colocation Enforcer | PreToolUse (Write) | Blocks type-based directories (`hooks/`, `components/`, `schemas/`, `presenters/`) inside `features/` |
| lint-on-edit | PostToolUse (Write/Edit) | Runs ESLint on `.js/.ts/.jsx/.tsx` files after edits; reports errors to Claude without blocking |
| notify-sound | Notification | Plays macOS Tink sound on notifications |

### Project configs

- **ESLint** — Flat config with TypeScript support
- **commitlint** — Conventional Commits enforcement via git hook

## How enforcement works

dojo-kit uses three layers to ensure Claude follows the architecture patterns:

1. **CLAUDE.md injection** (always-on) — `/dojo-kit-init` injects architecture rules into your project's CLAUDE.md. These load on every conversation, ensuring patterns are followed even when skills don't trigger.

2. **PreToolUse hooks** (active enforcement) — The colocation enforcer hook blocks file writes to type-based directories inside features before they happen.

3. **Skills** (on-demand detail) — When scaffolding new features, skills load detailed specifications with examples, anti-patterns, and reference docs.

## Plugin structure

```
.claude-plugin/plugin.json   Plugin manifest
skills/                      7 skills with reference docs
commands/                    Slash commands
hooks/hooks.json             Hook definitions
scripts/                     Hook and git hook scripts
docs/references/             Shared reference documents
```

## License

MIT
