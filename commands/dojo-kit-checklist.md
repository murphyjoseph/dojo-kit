---
name: dojo-kit-checklist
description: Audit the codebase across 10 health categories and output a prioritized docs/CHECKLIST.md with trackable checkboxes.
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash(ls:*)
  - AskUserQuestion
---

# dojo-kit checklist

Audit the current project's codebase for health issues across 10 categories and produce a prioritized `docs/CHECKLIST.md` with markdown checkboxes.

Read the audit categories at `${CLAUDE_PLUGIN_ROOT}/docs/references/checklist-categories.md` before starting.

## Steps

### 1. Check for existing checklist

Look for `docs/CHECKLIST.md` in the project root.

**If it exists:**
- Read the file
- Parse all `- [x]` items — these are completed and must be preserved
- Parse all `- [ ]` items — these will be re-evaluated (kept if still valid, removed if stale)
- Note the previous audit date from the header

**If it does not exist:**
- This is a fresh audit — no items to preserve

### 2. Detect project structure

Before auditing, understand the project layout:

- Glob for `src/**/*` to understand the directory structure
- Identify the framework (check for `next.config.*`, `remix.config.*`, `astro.config.*`, `vite.config.*`)
- Identify key directories: features/, components/, lib/, app/, pages/, api/
- Read `package.json` to understand dependencies

This context is needed to tailor search strategies per category.

### 3. Audit each category interactively

Read `${CLAUDE_PLUGIN_ROOT}/docs/references/checklist-categories.md` and process categories in this order:

1. Error Handling (Critical)
2. Data Validation (Critical)
3. Critical Gaps (High)
4. Code Simplification (High)
5. Code Smells (High)
6. Performance (Medium)
7. Interactivity (Medium)
8. Documentation (Low)
9. AI Context / CLAUDE.md (Low)
10. Code Readability (Low)

**For each category:**

1. Follow the **search strategy** from the reference doc to scan the codebase
2. Classify each finding using the **severity guide**
3. Present a summary to the user via `AskUserQuestion`:

> **[Category Name]** — Found N issues.
>
> [List the top findings briefly]

Options:
- **"Add these findings"** — include all findings in the checklist
- **"Skip this category"** — exclude entirely, move to next
- **"Let me give feedback"** — user provides input, adjust findings accordingly

4. Collect approved findings for the output

### 4. Merge with existing checklist

If a previous `docs/CHECKLIST.md` existed:

- **Preserve** all `- [x]` completed items in their original categories
- **Keep** any `- [ ]` items that are still valid (issue still exists in codebase)
- **Remove** stale `- [ ]` items where the file no longer exists or the issue is resolved
- **Add** new findings from this audit

If no previous checklist existed, all findings are new.

### 5. Write docs/CHECKLIST.md

Create the `docs/` directory if it doesn't exist. Write the file with this structure:

```
# Codebase Checklist

> Last audited: YYYY-MM-DD

## Critical

### [Category Name]
- [ ] `file/path.ts:line` — concise description of finding
- [x] `file/path.ts:line` — completed item description *(completed YYYY-MM-DD)*

## High

### [Category Name]
- [ ] `file/path.ts:line` — concise description of finding

## Medium

### [Category Name]
- [ ] `file/path.ts:line` — concise description of finding

## Low

### [Category Name]
- [ ] `file/path.ts:line` — concise description of finding
```

**Format rules:**
- Group by severity: Critical → High → Medium → Low
- Within each severity, group by category name
- Each item: `- [ ]` + backtick-wrapped file path (with line number when relevant) + ` — ` + concise description
- Completed items: `- [x]` + file path + description + ` *(completed YYYY-MM-DD)*`
- Omit severity sections that have zero findings
- Omit category headings that have zero findings
- Set the "Last audited" date to today

### 6. Present summary

After writing the file, tell the user:

- Total findings by severity (e.g., "3 critical, 5 high, 4 medium, 2 low")
- How many items were preserved from previous audit
- How many stale items were removed
- Where to find the file: `docs/CHECKLIST.md`
