# 001 — Dojo-kit is a Plugin

## Decision

Dojo-kit is a Claude Code plugin — not a CLI tool, not a template engine, not a monorepo of packages. The plugin system natively handles portability (`claude plugin install`), and the plugin bundles skills, hooks, MCP/LSP configs, and commands.

## Context

Early iterations explored a `@dojo-kit/schematic` package using plop/handlebars to generate code from learned conventions. This added a code generation pipeline on top of an AI that already reads examples and follows patterns. The complexity wasn't justified — well-written skill files with reference docs achieve the same outcome.

## What This Means

- The schematic package and plop machinery will be removed
- Philosophy docs become skill reference files
- A `/dojo-kit-init` command handles per-project setup
- A `dojo-kit.yaml` is generated per project to record decisions
- Skills, hooks, MCP/LSP configs are installed via the plugin system

## Plugin Structure

```
dojo-kit-plugin/
├── .claude-plugin/plugin.json
├── skills/
│   ├── architecture/           # boundary-first + services
│   ├── data-flow/              # errors-as-data + API pipeline
│   ├── ui-patterns/            # forms + features/views
│   ├── project-standards/      # repo hygiene, hard rules
│   ├── commit/                 # git commit conventions
│   └── pull-request/           # PR creation workflow
├── commands/
│   └── dojo-kit-init.md
├── hooks/hooks.json
├── .mcp.json
├── .lsp.json
└── scripts/
```
