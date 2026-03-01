# Skill Triggering Fixes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix five bottlenecks preventing dojo-kit skills from producing correctly-patterned code during scaffolding.

**Architecture:** All changes are to skill markdown files (SKILL.md frontmatter descriptions, SKILL.md body content) plus one new skill (`scaffolding`). No code, no tests — these are prompt engineering changes to plugin skills. The commit and pull-request skills get removed as they duplicate Claude Code built-in behavior.

**Tech Stack:** Markdown, YAML frontmatter

---

### Task 1: Create the `scaffolding` orchestration skill

This is the highest-impact change. Today, skills fire independently with no coordination. This skill triggers on "create page/feature/component/route" and tells Claude which other skills to invoke and in what order.

**Files:**
- Create: `skills/scaffolding/SKILL.md`

**Step 1: Create the skill file**

```markdown
---
name: scaffolding
description: Orchestrate feature scaffolding with correct architecture patterns.
  Use when creating a new page, route, feature, component, form, search view,
  list view, detail view, CRUD interface, or any UI that calls an API. Also use
  when the user says build, scaffold, generate, wire up, or create for any
  frontend work. This skill coordinates architecture, ui-patterns, data-flow,
  and project-standards so they apply together — not in isolation.
---

# Scaffolding

When creating any new feature, page, or component that touches an API or manages state, apply dojo-kit patterns from the start. Never scaffold a monolith with the intent to refactor later.

**This skill orchestrates other skills.** You must consult each one during scaffolding — they are not optional.

## Scaffolding Checklist

Before writing any code for a new feature, page, or component:

1. **Architecture** (`architecture` skill) — determine which layer each file belongs to (routes, features, shared, platform). Map the import flow. Identify if any new shared or platform code is needed.

2. **File structure** (`project-standards` skill) — name every file in kebab-case with functional suffixes. Plan the directory layout. No barrel files.

3. **API integration** (`data-flow` skill) — if the feature calls any API, create the pipeline files (definition, unpack, factory, consumer hook). Set up Result types. Never call `fetch()` from feature code.

4. **Component structure** (`ui-patterns` skill):
   - **Forms with API calls** → always create three files: schema, submission hook, component. Consult `ui-patterns/references/forms.md` for the full specification.
   - **Data display with loading/empty/error states** → always create three layers: orchestrator hook, presenter function, view component. Consult `ui-patterns/references/features-and-views.md` for the full specification.

5. **Feature portability** (`architecture` skill) — verify features don't import from routes or sibling features. Toasts, navigation, and analytics happen via `onSuccess`/`onAction` callbacks, never inside the feature.

## Output: What a Scaffolded Feature Looks Like

### Form feature (e.g. "create item")

```
features/items/
  schemas/item-form.schema.ts        ← Zod schema, single validation truth
  hooks/use-item-form.ts             ← Submission hook: mutations, error mapping, isPending
  components/item-form.tsx           ← Thin render layer: form library setup + fields
  api/create-item.definition.ts      ← Endpoint, method, request/response schemas
  api/create-item.unpack.ts          ← Response variants → Result
  api/create-item.factory.ts         ← Gateway wrapper, try/catch → Result
  hooks/use-create-item.ts           ← React Query consumer hook
```

The route file composes the feature and handles consequences:

```typescript
// routes/create-item/index.tsx
<ItemForm onSuccess={(item) => {
  toaster.create({ title: 'Item created', type: 'success' });
  navigate({ to: '/items/$id', params: { id: item.id } });
}} />
```

### Data display feature (e.g. "search items")

```
features/items/
  hooks/use-item-search.ts           ← Orchestrator: fetches data, manages state
  presenters/item-search.presenter.ts ← Pure function: data → view contract with renderAs
  components/item-search-view.tsx    ← Renders the contract, no logic
  api/search-items.definition.ts     ← Endpoint, method, schemas
  api/search-items.unpack.ts         ← Response → Result
  api/search-items.factory.ts        ← Gateway wrapper
  hooks/use-search-items.ts          ← React Query consumer hook
```

## What NOT to Generate

These are violations — if you see these patterns in your output, stop and fix them:

| Violation | Correct approach |
|---|---|
| `useMutation()` inside a form component | Move to submission hook |
| `toaster.create()` inside a feature | Fire `onSuccess`, let route handle toasts |
| `router.push()` inside a feature | Fire `onSuccess`, let route handle navigation |
| `useState` per field instead of a form library + schema | Use schema file + form library |
| Inline `fetch()` or direct API client call in feature | Use the API pipeline (define/unpack/factory/consume) |
| Loading/empty/error handled with inline ternaries in one component | Use presenter + view contract with `renderAs` |
| All logic in one file | Split by concern: schema, hook, component (forms) or orchestrator, presenter, view (features) |

## When to Simplify

Not every page needs the full pipeline. Use judgment:

| Situation | Approach |
|---|---|
| Static page with no API calls or state | No pattern needed — just a component |
| Simple display with one API call, no error/empty states | Orchestrator hook + component (skip presenter) |
| Form with 1 field, no API call | Inline — the separation is overhead |
| Prototype or proof of concept | Note that patterns are skipped, apply later |
```

**Step 2: Commit**

```bash
git add skills/scaffolding/SKILL.md
git commit -m "feat(skills): add scaffolding orchestration skill"
```

---

### Task 2: Make reference loading proactive in `ui-patterns` SKILL.md

The current decision triggers are reactive ("This form is getting complicated" → consult reference). Change them to proactive: always consult references when creating new forms or features.

**Files:**
- Modify: `skills/ui-patterns/SKILL.md` (lines 75-92, Decision Triggers and References sections)

**Step 1: Replace the Decision Triggers and References sections**

Replace the existing Decision Triggers section (lines 75-78) with:

```markdown
## Mandatory Reference Loading

When creating a new form or feature component, **always** read the full reference before writing code:

- **Creating a form with an API call** → read `references/forms.md` first — it contains the complete specification, anti-patterns, and error flow
- **Creating a component with loading/empty/error states** → read `references/features-and-views.md` first — it contains the presenter pattern, contract typing, and decision guide

Do not skip reference loading when scaffolding from scratch. The references contain concrete examples and anti-patterns that prevent the most common mistakes.
```

Keep the existing References section (lines 89-92) as-is — it still serves as a quick index.

**Step 2: Commit**

```bash
git add skills/ui-patterns/SKILL.md
git commit -m "fix(ui-patterns): make reference loading proactive instead of reactive"
```

---

### Task 3: Add anti-pattern examples to `ui-patterns` SKILL.md

The anti-pattern section currently only lives in `references/forms.md`. Add a brief anti-pattern + correct pattern pair directly in SKILL.md so Claude sees it without loading references.

**Files:**
- Modify: `skills/ui-patterns/SKILL.md` (insert after line 50, before Feature/View Pattern section)

**Step 1: Add anti-pattern section after the form `onSuccess` example**

Insert after the closing of the Form Pattern code example (after line 50 `// The form knows nothing about toasts, routing, or closing dialogs.`) and before `## Feature/View Pattern` (line 52):

```markdown

### Form Anti-Pattern: The Monolith

This is what happens when the submission hook is skipped — **do not generate this**:

```typescript
// BAD — every line marked is a violation
function CreateItemPage() {
  const mutation = useMutation({ mutationFn: createItem });  // violation: mutation in component

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    mutation.mutate(payload, {
      onSuccess: () => {
        toaster.success({ title: 'Created' });               // violation: form decides consequences
        setTitle('');                                          // violation: manual field reset
      },
    });
  };
  // ... useState per field, inline rendering
}
```

The correct version has three files (schema + submission hook + component) as specified above. The form fires `onSuccess`; the parent handles toasts, navigation, and resets.
```

**Step 2: Add feature/view anti-pattern after the View Contract Shape table**

Insert after the View Contract Shape table (after line 72) and before `## Mandatory Reference Loading`:

```markdown

### Feature Anti-Pattern: The Kitchen Sink Component

This is what happens when orchestrate/present/render aren't separated — **do not generate this**:

```typescript
// BAD — data fetching, conditional logic, and rendering in one component
function SearchPage() {
  const { data, isLoading, error } = useQuery({ ... });       // orchestration mixed with rendering

  return (
    <>
      {isLoading ? <Skeleton /> : null}                        // violation: conditional logic in JSX
      {error ? <Text color="error">{error.message}</Text> : null}
      {data?.length === 0 ? <EmptyState /> : null}             // violation: business logic in view
      {data?.map(item => <Card key={item.id} item={item} />)}
    </>
  );
}
```

The correct version uses an orchestrator hook (owns data fetching), a presenter pure function (returns a `renderAs` contract), and a view component (narrows on `renderAs`, renders the contract).
```

**Step 3: Commit**

```bash
git add skills/ui-patterns/SKILL.md
git commit -m "fix(ui-patterns): add anti-pattern examples to SKILL.md"
```

---

### Task 4: Add file-listing output expectations to `ui-patterns` and `data-flow` SKILL.md

Show Claude exactly what files should be created, not just what rules apply.

**Files:**
- Modify: `skills/ui-patterns/SKILL.md` — add expected file listings after each pattern section
- Modify: `skills/data-flow/SKILL.md` — add expected file listing after pipeline stages

**Step 1: Add file listing to ui-patterns Form Pattern section**

Insert after the `onSuccess` code example block (after line 50, before the new anti-pattern section from Task 3) in ui-patterns SKILL.md:

```markdown

### Expected Files for a Form Feature

When scaffolding a form with an API call (e.g. "item form"), create these files:

```
features/<domain>/schemas/<name>-form.schema.ts     ← Zod schema, types
features/<domain>/hooks/use-<name>-form.ts           ← Submission hook
features/<domain>/components/<name>-form.tsx          ← Thin render component
```
```

**Step 2: Add file listing to ui-patterns Feature/View Pattern section**

Insert after the View Contract Shape table (after line 72, before the new anti-pattern section from Task 3):

```markdown

### Expected Files for a Feature with State

When scaffolding a component with loading/empty/error states (e.g. "team members list"), create these files:

```
features/<domain>/hooks/use-<name>.ts                ← Orchestrator hook
features/<domain>/presenters/<name>.presenter.ts     ← Pure presenter function
features/<domain>/components/<name>-view.tsx          ← View component
```
```

**Step 3: Add file listing to data-flow SKILL.md**

Insert after the API Pipeline table (after line 59) in data-flow SKILL.md:

```markdown

### Expected Files for an API Integration

When scaffolding a new API endpoint integration (e.g. "submit order"), create these files:

```
features/<domain>/api/<name>.definition.ts           ← Endpoint, method, schemas
features/<domain>/api/<name>.unpack.ts               ← Response variants → Result
features/<domain>/api/<name>.factory.ts              ← Gateway wrapper, try/catch → Result
features/<domain>/hooks/use-<name>.ts                ← Framework consumer hook
```

For simple, single-use API calls, combine definition + unpack into one file. Use the full four-file pipeline when an API call is reused or its response shape has multiple variants.
```

**Step 4: Commit**

```bash
git add skills/ui-patterns/SKILL.md skills/data-flow/SKILL.md
git commit -m "fix(skills): add expected file listings to ui-patterns and data-flow"
```

---

### Task 5: Broaden `data-flow` skill description for better triggering

The current description uses specialist language ("writing functions that can fail, creating API integrations"). Users say "create a page" or "build a feature" — the description needs to match those prompts.

**Files:**
- Modify: `skills/data-flow/SKILL.md` (lines 2-5, frontmatter description)

**Step 1: Update the frontmatter description**

Replace the existing description:

```yaml
description: Error handling and API pipeline patterns. Use when writing functions
  that can fail, creating API integrations, handling server responses, designing
  error types, or deciding between throwing and returning errors.
```

With:

```yaml
description: Error handling and API pipeline patterns. Use when creating any
  feature, page, or component that calls an API — including forms that submit
  data, pages that fetch and display data, or any code that talks to a server.
  Also use when writing functions that can fail, handling server responses,
  designing error types, or deciding between throwing and returning errors.
```

**Step 2: Commit**

```bash
git add skills/data-flow/SKILL.md
git commit -m "fix(data-flow): broaden skill description for scaffolding triggers"
```

---

### Task 6: Remove `commit` and `pull-request` skills

These duplicate Claude Code's built-in commit and PR creation behavior. The PreToolUse hook + commitlint already enforce conventional commit format. Claude Code's built-in PR flow already generates structured descriptions. The unique value (when to commit, scoping, PR template sections) isn't strong enough to justify the context window cost.

**Files:**
- Delete: `skills/commit/SKILL.md`
- Delete: `skills/commit/references/commit-message-examples.md`
- Delete: `skills/commit/references/advanced-patterns.md`
- Delete: `skills/pull-request/SKILL.md`
- Delete: `skills/pull-request/references/section-guide.md`
- Delete: entire `skills/commit/` directory
- Delete: entire `skills/pull-request/` directory
- Modify: `CLAUDE.md` — remove commit and pull-request from the Skills table
- Modify: `skills/planning/SKILL.md` — remove reference to `commit` skill in Cross-Skill Integration table (line 70)

**Step 1: Remove skill directories**

```bash
rm -rf skills/commit/ skills/pull-request/
```

**Step 2: Update CLAUDE.md skills table**

Remove these two rows from the skills table:

```
| `commit` | Good git commits — scoping, conventional messages, when to commit |
| `pull-request` | Well-structured PRs using the project PR template |
```

**Step 3: Update planning SKILL.md cross-skill integration table**

Remove this row from the Cross-Skill Integration table (line 70):

```
| Implementation Order | `commit` | Scoping each step as a committable unit |
```

**Step 4: Commit**

```bash
git add -A
git commit -m "chore(skills): remove commit and pull-request skills

These duplicate Claude Code built-in behavior. Conventional commit
format is enforced by the PreToolUse hook and commitlint git hook.
PR creation is handled by Claude Code's built-in flow."
```

---

### Task 7: Update CLAUDE.md skill count and table

Reflect the changes: one new skill (scaffolding), two removed (commit, pull-request). Net count goes from 9 to 8.

**Files:**
- Modify: `CLAUDE.md` — update skill count, add scaffolding to table

**Step 1: Update the skills section**

Change `Skills (9 total)` to `Skills (8 total)` in the repository structure comment.

Add scaffolding to the skills table:

```
| `scaffolding` | Orchestrates feature scaffolding — coordinates architecture, ui-patterns, data-flow, and project-standards |
```

**Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md for skill changes"
```
