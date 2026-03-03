# Feature Component Pattern Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add `.feature.tsx` as a wiring layer to both form and data display patterns, making views purely presentational (no hooks, no `"use client"`).

**Architecture:** The feature component sits between the route and the view. Routes import `.feature.tsx` (not `.view.tsx`). The feature calls the controller, destructures the return, and passes individual props to the view. Views become pure components that receive typed props.

**Tech Stack:** Markdown skill files (no runtime code — this is a plugin documentation change)

---

### Task 1: Update ui-patterns SKILL.md — Form Pattern

**Files:**
- Modify: `skills/ui-patterns/SKILL.md:27-87`

**Step 1: Update the form concern table (line 31)**

Add the feature row and update the view row to clarify it receives props, not the controller hook.

Replace lines 27-31:
```markdown
| Concern | File | Owns | Does not own |
|---|---|---|---|
| **Schema** | `item-form.schema.ts` | Every field, constraint, error message | Submission, rendering, side effects |
| **Controller** | `item-form.controller.ts` | API calls, mutations, error mapping, payload construction, pending state | Rendering, navigation, what happens after success |
| **View** | `item-form.view.tsx` | Form library setup, field composition, layout, wiring the controller | Validation logic, API calls, deciding post-success behavior |
```

With:
```markdown
| Concern | File | Owns | Does not own |
|---|---|---|---|
| **Schema** | `item-form.schema.ts` | Every field, constraint, error message | Submission, rendering, side effects |
| **Controller** | `item-form.controller.ts` | API calls, mutations, error mapping, payload construction, pending state | Rendering, navigation, what happens after success |
| **Feature** | `item-form.feature.tsx` | Wiring controller → view via props, `"use client"` boundary | Logic, rendering, validation |
| **View** | `item-form.view.tsx` | Form library setup, field composition, layout from props | Hooks, `"use client"`, API calls, deciding post-success behavior |
```

**Step 2: Update the expected files section (lines 76-87)**

Replace lines 76-87:
```markdown
### Expected Files for a Form Feature

When scaffolding a form with an API call (e.g. "item form"), colocate all form files together:

` ` `
features/<domain>/<concern>/
  <name>-form.schema.ts              ← Zod schema, types
  <name>-form.controller.ts          ← Submission logic: wraps mutations, error mapping
  <name>-form.view.tsx               ← Thin render component
` ` `

Never scatter these across `schemas/`, `hooks/`, `components/` directories. They belong together.
```

With:
```markdown
### Expected Files for a Form Feature

When scaffolding a form with an API call (e.g. "item form"), colocate all form files together:

` ` `
features/<domain>/<concern>/
  <name>-form.schema.ts              ← Zod schema, types
  <name>-form.controller.ts          ← "use client", submission logic: wraps mutations, error mapping
  <name>-form.feature.tsx            ← "use client", wires controller → view via props
  <name>-form.view.tsx               ← Pure render component, receives props (no hooks, no "use client")
` ` `

Never scatter these across `schemas/`, `hooks/`, `components/` directories. They belong together.

**Routes import the feature, not the view.** The feature component is the public entry point.
```

**Step 3: Commit**

```bash
git add skills/ui-patterns/SKILL.md
git commit -m "docs(ui-patterns): add feature component to form pattern"
```

---

### Task 2: Update ui-patterns SKILL.md — Feature/View Pattern

**Files:**
- Modify: `skills/ui-patterns/SKILL.md:89-121`

**Step 1: Update the feature/view layer table (lines 93-97)**

Replace lines 93-97:
```markdown
| Layer | File suffix | Responsibility | Uses framework? |
|---|---|---|---|
| **Controller** | `.controller.ts` | Fetch data, manage state, own side effects | Yes (hooks, context) |
| **Presenter** | `.presenter.ts` | Pure function: raw data → view contract | No |
| **View** | `.view.tsx` | Draw the contract, fire callbacks | Yes (JSX) |
```

With:
```markdown
| Layer | File suffix | Responsibility | Uses framework? |
|---|---|---|---|
| **Controller** | `.controller.ts` | Fetch data, manage state, own side effects | Yes (hooks, context) |
| **Presenter** | `.presenter.ts` | Pure function: raw data → view contract | No |
| **Feature** | `.feature.tsx` | Wire controller → view via props, `"use client"` boundary | Yes (calls controller hook) |
| **View** | `.view.tsx` | Draw the contract from props, fire callbacks | Yes (JSX only, no hooks) |
```

**Step 2: Update expected files section (lines 110-121)**

Replace lines 110-121:
```markdown
### Expected Files for a Feature with State

When scaffolding a component with loading/empty/error states (e.g. "team members list"), colocate presenter and view together:

` ` `
features/<domain>/<concern>/
  <name>.presenter.ts                ← Pure presenter function
  <name>.view.tsx                    ← View component
  <name>.controller.ts              ← Orchestrator: fetches data, wires presenter
` ` `

Never put presenters in a separate `presenters/` directory — they belong next to the view they serve.
```

With:
```markdown
### Expected Files for a Feature with State

When scaffolding a component with loading/empty/error states (e.g. "team members list"), colocate all files together:

` ` `
features/<domain>/<concern>/
  <name>.presenter.ts                ← Pure presenter function
  <name>.controller.ts              ← "use client", orchestrator: fetches data, wires presenter
  <name>.feature.tsx                 ← "use client", wires controller → view via props
  <name>.view.tsx                    ← Pure view component, receives props (no hooks, no "use client")
` ` `

Never put presenters in a separate `presenters/` directory — they belong next to the view they serve.

**Routes import the feature, not the view.** The feature component is the public entry point.
```

**Step 3: Commit**

```bash
git add skills/ui-patterns/SKILL.md
git commit -m "docs(ui-patterns): add feature component to data display pattern"
```

---

### Task 3: Update ui-patterns SKILL.md — When to Use Table and Pattern Decision

**Files:**
- Modify: `skills/ui-patterns/SKILL.md:154-163`

**Step 1: Update the "when to use each pattern" table (lines 156-162)**

Replace lines 156-162:
```markdown
| Signal | Pattern |
|---|---|
| Form with 2+ fields or an API call | Form pattern — always (`.schema.ts` + `.controller.ts` + `.view.tsx` in separate files) |
| Form with 1 field, no API call | Inline — the separation is overhead |
| Component that fetches data or has loading/empty/error states | Feature/view pattern (`.controller.ts` + `.presenter.ts` + `.view.tsx`) |
| Component with conditional logic, computed display, permission-based UI | Feature/view pattern (`.controller.ts` + `.presenter.ts` + `.view.tsx`) |
| Static component that receives props and renders | No pattern needed |
```

With:
```markdown
| Signal | Pattern |
|---|---|
| Form with 2+ fields or an API call | Form pattern — always (`.schema.ts` + `.controller.ts` + `.feature.tsx` + `.view.tsx`) |
| Form with 1 field, no API call | Inline — the separation is overhead |
| Component that fetches data or has loading/empty/error states | Feature/view pattern (`.controller.ts` + `.presenter.ts` + `.feature.tsx` + `.view.tsx`) |
| Component with conditional logic, computed display, permission-based UI | Feature/view pattern (`.controller.ts` + `.presenter.ts` + `.feature.tsx` + `.view.tsx`) |
| Static component that receives props and renders | No pattern needed |
```

**Step 2: Commit**

```bash
git add skills/ui-patterns/SKILL.md
git commit -m "docs(ui-patterns): update pattern decision table with feature component"
```

---

### Task 4: Update forms.md Reference — View Section

**Files:**
- Modify: `skills/ui-patterns/references/forms.md:95-134`

**Step 1: Replace the View section to show it receives props instead of calling the controller**

Replace lines 95-134 (the entire "### 3. View" section):
```markdown
### 3. View (Thin Render Layer)

The view sets up the form library, composes fields, and wires the controller. It does not import mutations, construct payloads, or decide what happens after success.

` ` `typescript
// features/items/create-item/item-form.view.tsx

interface ItemFormProps {
  item?: Item | null;
  onSuccess: (item: Item) => void;
}

export function ItemForm({ item, onSuccess }: ItemFormProps) {
  const { handleSubmit, isPending, error } = useItemForm({ item, onSuccess });

  // Form library setup lives here — this is fine
  const form = useForm({
    defaultValues: {
      title: item?.title ?? '',
      description: item?.description ?? '',
      priority: item?.priority ?? 3,
      status: item?.status ?? 'todo',
    },
    onSubmit: async ({ value }) => handleSubmit(value),
    // ...library-specific config (resolver, validators, etc.)
  });

  return (
    <form onSubmit={/* library-specific submit wiring */}>
      {error && <FormBanner message={error.message} />}
      {/* Field composition — library-specific */}
      <SubmitButton loading={isPending}>
        {item ? 'Save' : 'Create'}
      </SubmitButton>
    </form>
  );
}
` ` `

**The view imports the controller, not the mutations.** If you see `useCreateItem()` or `useMutation()` in a `.view.tsx` file, that's a violation.
```

With:
```markdown
### 3. Feature (Wiring Layer)

The feature component is the `"use client"` boundary. It calls the controller hook and passes props to the view. It contains no logic — just wiring.

` ` `typescript
// features/items/create-item/item-form.feature.tsx
"use client"

import { useItemForm } from "./item-form.controller"
import { ItemFormView } from "./item-form.view"

interface ItemFormFeatureProps {
  item?: Item | null;
  onSuccess: (item: Item) => void;
}

export function ItemFormFeature({ item, onSuccess }: ItemFormFeatureProps) {
  const { handleSubmit, isPending, error } = useItemForm({ item, onSuccess });
  return <ItemFormView item={item} handleSubmit={handleSubmit} isPending={isPending} error={error} />
}
` ` `

### 4. View (Pure Render Layer)

The view receives all data as props. No hooks, no `"use client"`. It sets up the form library, composes fields, and renders — nothing else.

` ` `typescript
// features/items/create-item/item-form.view.tsx
import type { ItemFormValues } from "./item-form.schema"

interface ItemFormViewProps {
  item?: Item | null;
  handleSubmit: (values: ItemFormValues) => Promise<void>;
  isPending: boolean;
  error: Error | null;
}

export function ItemFormView({ item, handleSubmit, isPending, error }: ItemFormViewProps) {
  const form = useForm({
    defaultValues: {
      title: item?.title ?? '',
      description: item?.description ?? '',
      priority: item?.priority ?? 3,
      status: item?.status ?? 'todo',
    },
    onSubmit: async ({ value }) => handleSubmit(value),
  });

  return (
    <form onSubmit={/* library-specific submit wiring */}>
      {error && <FormBanner message={error.message} />}
      {/* Field composition — library-specific */}
      <SubmitButton loading={isPending}>
        {item ? 'Save' : 'Create'}
      </SubmitButton>
    </form>
  );
}
` ` `

**The view never imports the controller or mutations.** If you see `useItemForm()`, `useCreateItem()`, or `useMutation()` in a `.view.tsx` file, that's a violation. The feature component wires them together.
```

**Step 2: Commit**

```bash
git add skills/ui-patterns/references/forms.md
git commit -m "docs(ui-patterns): add feature component to form reference"
```

---

### Task 5: Update features-and-views.md Reference — Controller and View Sections

**Files:**
- Modify: `skills/ui-patterns/references/features-and-views.md:107-143`

**Step 1: Add Feature section and update View section**

Replace lines 107-143 (from "### View" to end of view code):
```markdown
### View

Receives the contract and draws it. No data fetching, no business logic. Narrows on `renderAs`. Lives in a `.view.tsx` file.

` ` `typescript
// features/team/members/team-members.view.tsx
export function TeamMembersView(props: TeamMembersContract) {
  ...
}
` ` `
```

With a new Feature section followed by updated View section:

```markdown
### Feature

The `"use client"` boundary. Calls the controller hook, destructures the contract, and passes props to the view. Contains no logic — just wiring. Lives in a `.feature.tsx` file.

` ` `typescript
// features/team/members/team-members.feature.tsx
"use client"

import { useTeamMembers } from "./team-members.controller"
import { TeamMembersView } from "./team-members.view"

export function TeamMembersFeature({ teamId }: { teamId: string }) {
  const contract = useTeamMembers(teamId)
  return <TeamMembersView {...contract} />
}
` ` `

**Routes import the feature, not the view.** The feature component is the public entry point.

### View

Receives the contract as props and draws it. No hooks, no `"use client"`, no data fetching, no business logic. Narrows on `renderAs`. Lives in a `.view.tsx` file.

` ` `typescript
// features/team/members/team-members.view.tsx
export function TeamMembersView(props: TeamMembersContract) {
  if (props.renderAs === 'loading') {
    return <Skeleton />;
  }

  if (props.renderAs === 'error') {
    return <ErrorBanner message={props.display.errorMessage} onRetry={props.effects.onRetry} />;
  }

  if (props.renderAs === 'empty') {
    return (
      <EmptyState message={props.display.emptyMessage}>
        {props.instructions.showInvitePrompt && <InviteButton />}
      </EmptyState>
    );
  }

  return (
    <MemberList>
      <Header count={props.display.memberCount} />
      {props.display.members.map((member) => (
        <MemberCard
          key={member.fullName}
          {...member}
          showEdit={props.instructions.showEditButton}
          showRemove={props.instructions.showRemoveButton}
        />
      ))}
    </MemberList>
  );
}
` ` `
```

**Step 2: Update the quick reference table (lines 7-12)**

Replace:
```markdown
| Rule | Description |
|---|---|
| Three layers | Controller → Presenter → View |
| Presenter is a pure function | Input data → output contract, no hooks or side effects |
| View renders the contract | No business logic, no data fetching, narrows on `renderAs` |
| View contract has four sections | `renderAs`, `display`, `instructions`, `effects` |
```

With:
```markdown
| Rule | Description |
|---|---|
| Four layers | Controller → Presenter → Feature → View |
| Presenter is a pure function | Input data → output contract, no hooks or side effects |
| Feature is the wiring layer | Calls controller, passes props to view, owns `"use client"` |
| View renders from props | No hooks, no `"use client"`, no data fetching, narrows on `renderAs` |
| View contract has four sections | `renderAs`, `display`, `instructions`, `effects` |
```

**Step 3: Commit**

```bash
git add skills/ui-patterns/references/features-and-views.md
git commit -m "docs(ui-patterns): add feature component to features-and-views reference"
```

---

### Task 6: Update scaffolding SKILL.md — File Naming and Examples

**Files:**
- Modify: `skills/scaffolding/SKILL.md:45-103`

**Step 1: Add `.feature.tsx` to the file naming convention table (lines 49-59)**

Add a row after `.view.tsx`:
```
| `.feature.tsx` | Wiring component: calls controller, passes props to view | `item-form.feature.tsx` |
```

**Step 2: Update form feature example (lines 61-86)**

Replace lines 63-86:
```markdown
` ` `
features/items/
  types.ts                           ← Shared type definitions
  api/
    items.api.ts                     ← Gateway functions
    items.queries.ts                 ← useItems, useSearchItems
    items.mutations.ts               ← useCreateItem, useUpdateItem, useDeleteItem
  create-item/
    item-form.schema.ts              ← Zod schema, single validation truth
    item-form.controller.ts          ← Submission logic: wraps mutations, error mapping, isPending
    item-form.controller.test.ts     ← Tests for submission logic
    item-form.view.tsx               ← Thin render layer: form library setup + fields
    item-form.styles.ts              ← Colocated styles (if applicable)
` ` `

The route file composes the feature and handles consequences:

` ` `typescript
// routes/create-item/index.tsx
<ItemForm onSuccess={(item) => {
  toaster.create({ title: 'Item created', type: 'success' });
  navigate({ to: '/items/$id', params: { id: item.id } });
}} />
` ` `
```

With:
```markdown
` ` `
features/items/
  types.ts                           ← Shared type definitions
  api/
    items.api.ts                     ← Gateway functions
    items.queries.ts                 ← useItems, useSearchItems
    items.mutations.ts               ← useCreateItem, useUpdateItem, useDeleteItem
  create-item/
    item-form.schema.ts              ← Zod schema, single validation truth
    item-form.controller.ts          ← "use client", submission logic: wraps mutations, error mapping
    item-form.controller.test.ts     ← Tests for submission logic
    item-form.feature.tsx            ← "use client", wires controller → view via props
    item-form.view.tsx               ← Pure render layer: receives props (no hooks, no "use client")
    item-form.styles.ts              ← Colocated styles (if applicable)
` ` `

The route file imports the feature (not the view) and handles consequences:

` ` `typescript
// routes/create-item/index.tsx
<ItemFormFeature onSuccess={(item) => {
  toaster.create({ title: 'Item created', type: 'success' });
  navigate({ to: '/items/$id', params: { id: item.id } });
}} />
` ` `
```

**Step 3: Update data display feature example (lines 88-103)**

Replace lines 90-103:
```markdown
` ` `
features/items/
  types.ts                           ← Shared type definitions
  api/
    items.api.ts                     ← Gateway functions
    items.queries.ts                 ← useItems, useSearchItems
  search/
    search.presenter.ts              ← Pure function: data → view contract with renderAs
    search.presenter.test.ts         ← Tests for presenter logic
    search.controller.ts             ← Controller: fetches data, wires presenter
    search.controller.test.ts        ← Tests for controller logic
    search.view.tsx                  ← Renders the contract, no logic
    search.styles.ts                 ← Colocated styles (if applicable)
` ` `
```

With:
```markdown
` ` `
features/items/
  types.ts                           ← Shared type definitions
  api/
    items.api.ts                     ← Gateway functions
    items.queries.ts                 ← useItems, useSearchItems
  search/
    search.presenter.ts              ← Pure function: data → view contract with renderAs
    search.presenter.test.ts         ← Tests for presenter logic
    search.controller.ts             ← "use client", controller: fetches data, wires presenter
    search.controller.test.ts        ← Tests for controller logic
    search.feature.tsx               ← "use client", wires controller → view via props
    search.view.tsx                  ← Pure render: receives props (no hooks, no "use client")
    search.styles.ts                 ← Colocated styles (if applicable)
` ` `
```

**Step 4: Commit**

```bash
git add skills/scaffolding/SKILL.md
git commit -m "docs(scaffolding): add feature component to file naming and examples"
```

---

### Task 7: Update scaffolding SKILL.md — Checklist and Violations Table

**Files:**
- Modify: `skills/scaffolding/SKILL.md:27-29` and `skills/scaffolding/SKILL.md:105-121`

**Step 1: Update the component structure checklist item (lines 27-29)**

Replace lines 27-29:
```markdown
4. **Component structure** (`ui-patterns` skill):
   - **Forms with API calls** → always create three files: `.schema.ts`, `.controller.ts`, `.view.tsx`. Consult `ui-patterns/references/forms.md` for the full specification.
   - **Data display with loading/empty/error states** → always create three layers: `.controller.ts`, `.presenter.ts`, `.view.tsx`. Consult `ui-patterns/references/features-and-views.md` for the full specification.
```

With:
```markdown
4. **Component structure** (`ui-patterns` skill):
   - **Forms with API calls** → always create four files: `.schema.ts`, `.controller.ts`, `.feature.tsx`, `.view.tsx`. Consult `ui-patterns/references/forms.md` for the full specification.
   - **Data display with loading/empty/error states** → always create four files: `.controller.ts`, `.presenter.ts`, `.feature.tsx`, `.view.tsx`. Consult `ui-patterns/references/features-and-views.md` for the full specification.
   - **The `.feature.tsx` is the wiring layer** — it owns `"use client"`, calls the controller hook, and passes props to the view. Routes import the feature, never the view directly.
```

**Step 2: Add violations to the "What NOT to Generate" table (lines 109-121)**

Add these rows to the violations table:
```markdown
| Hooks (`useController()`, `useState`) in a `.view.tsx` | Move hook calls to `.feature.tsx`, pass data as props to the view |
| `"use client"` on a `.view.tsx` file | `"use client"` belongs on `.feature.tsx` and `.controller.ts` only |
| Route imports `.view.tsx` directly | Routes import `.feature.tsx` — the feature is the public entry point |
```

**Step 3: Commit**

```bash
git add skills/scaffolding/SKILL.md
git commit -m "docs(scaffolding): update checklist and violations for feature component"
```
