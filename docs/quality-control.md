# Quality Control

Known bugs, inconsistent behaviors, and reliability issues to fix.

## dojo-kit-init: Companion Selection Skipped or Auto-Applied

**Severity:** High — user choice is bypassed

Step 8 of the init command requires using `AskUserQuestion` with `multiSelect: true` to present companion plugins/tools. In practice, Claude sometimes:

- Skips the companion question entirely and moves on after generating `dojo-kit.yaml` and `CLAUDE.md`
- Auto-installs companions without asking, writing to `.claude/settings.json` or `.mcp.json` without user consent

The command spec is explicit: "Always ask about these companions" and uses `AskUserQuestion`. The issue is likely that Claude treats the step as optional or infers user intent from context rather than following the prescribed flow.

**Possible fixes:**

- Add stronger language in step 8: "You MUST ask — never skip or assume"
- Add a checklist gate at the end of the command that verifies each step was completed
- Consider a PostToolUse hook that validates `.claude/settings.json` and `.mcp.json` weren't modified without a preceding `AskUserQuestion` call
