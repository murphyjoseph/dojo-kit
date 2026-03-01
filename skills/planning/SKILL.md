---
name: planning
description: Plan before building. Use when implementing features, refactoring across
  boundaries, migrating data or APIs, adding new layers or services, or any work
  that will touch 3 or more files. Also use when the user asks to build, create,
  add, implement, migrate, refactor, redesign, or restructure something non-trivial.
  Write a plan document to docs/plans/ and wait for explicit approval before writing
  any implementation code.
---

# Planning

Multi-file work gets a written plan before any code is written. The plan lives in `docs/plans/`, and implementation does not start until the user approves it.

## When to Plan

| Signal | Action |
|---|---|
| Work touches 3+ files | Plan |
| New feature with UI, data, and API layers | Plan |
| Refactor that moves code across boundaries | Plan |
| Migration (data, API, dependency) | Plan |
| Single-file bug fix | Skip — just fix it |
| Adding a field to an existing form | Skip — scope is obvious |
| Docs-only change | Skip |
| User says "just do it" or "skip the plan" | Skip |

When in doubt, plan. A 5-minute plan saves an hour of rework.

## Workflow

### 1. Understand

- Read relevant code, configs, and tests
- Identify every file that will be created, modified, or deleted
- Check `dojo-kit.yaml` if it exists for stack context

### 2. Write the Plan

- Create `docs/plans/` if it doesn't exist
- Write the plan as `docs/plans/<slug>.md` using the template in `references/plan-template.md`
- The slug should be a short kebab-case name for the work (e.g., `checkout-feature`, `auth-migration`)

### 3. STOP — Wait for Approval

Present the plan to the user and ask for their review. **Do not proceed until the user explicitly approves.**

**Prohibited until approval:**
- Writing or editing any file outside `docs/plans/`
- Creating components, hooks, utilities, or tests
- Modifying existing source code
- Running code generation or scaffolding commands

Say something like: "Here's the plan — please review and let me know if you'd like any changes, or approve it so I can start implementation."

### 4. Implement from the Plan

Once approved, follow the plan's **Implementation Order** section step by step. Each step should be a committable unit. Reference the plan file if you need to revisit decisions.

## Cross-Skill Integration

The plan template maps directly to other dojo-kit skills. Use them when writing each section:

| Plan Section | Skill | What it provides |
|---|---|---|
| Architecture Impact | `architecture` | Boundary rules, import hierarchy, layer placement |
| File Breakdown | `architecture`, `project-standards` | File naming, directory structure, flat vs nested |
| Data Flow | `data-flow` | Result types, API pipeline stages, error handling |
| UI Plan | `ui-patterns` | Form architecture, feature/view separation |
| Implementation Order | `commit` | Scoping each step as a committable unit |

## Plan Quality Rules

- **Concrete file paths** — `src/features/checkout/checkout-form.tsx`, not "a checkout component"
- **Specific edge cases** — "What happens when the cart is empty and the user clicks submit?", not "handle edge cases"
- **Honest open questions** — If you don't know something, say so. Tag who should answer (user, team lead, designer)
- **No hand-waving** — Every section either has real content or is explicitly marked N/A with a reason
- **Brevity over exhaustiveness** — A plan that gets read beats a plan that covers everything

## References

- **`references/plan-template.md`** — Full plan template with section-by-section guidance
