# Feature Component Pattern

## Problem

Views currently call controller hooks directly, making them stateful client components. The `"use client"` directive lives on the view, coupling it to React's client boundary. Views should be pure presentational components receiving props.

## Solution

Introduce a `.feature.tsx` file as the wiring layer between controller/presenter and view. Applies to both form and data display patterns.

## File Responsibilities

| File | Role | Has hooks? | `"use client"`? |
|---|---|---|---|
| `.feature.tsx` | Wires controller → view via props | Yes (calls controller) | Yes |
| `.controller.ts` | Owns state, API calls, side effects | Yes | Yes |
| `.presenter.ts` | Pure data transformation (data display only) | No | No |
| `.schema.ts` | Validation rules (forms only) | No | No |
| `.view.tsx` | Pure render from props | No | No |

## Form Pattern

### File Structure

```
features/toppings/create-topping/
  create-topping.schema.ts        ← Zod validation
  create-topping.controller.ts    ← "use client", hooks, mutation logic
  create-topping.feature.tsx      ← "use client", wires controller → view
  create-topping.view.tsx          ← Pure component, props only
```

### Feature Component

```tsx
"use client"

import { useCreateToppingController } from "./create-topping.controller"
import { CreateToppingView } from "./create-topping.view"

export function CreateToppingFeature() {
  const { state, action, pending, formRef } = useCreateToppingController()
  return <CreateToppingView state={state} action={action} pending={pending} formRef={formRef} />
}
```

### View Component (no `"use client"`, no hooks)

```tsx
import type { RefObject } from "react"

type CreateToppingViewProps = {
  state: { topping?: { id: string; name: string; category: string }; error?: string }
  action: (formData: FormData) => void
  pending: boolean
  formRef: RefObject<HTMLFormElement>
}

export function CreateToppingView({ state, action, pending, formRef }: CreateToppingViewProps) {
  return (
    <form ref={formRef} action={action}>
      {/* pure rendering */}
    </form>
  )
}
```

## Data Display Pattern

### File Structure

```
features/items/search/
  search.presenter.ts             ← Pure function: data → contract
  search.controller.ts            ← "use client", fetches + calls presenter
  search.feature.tsx              ← "use client", wires controller → view
  search.view.tsx                  ← Pure component, renders contract props
```

### Feature Component

```tsx
"use client"

import { useSearchController } from "./search.controller"
import { SearchView } from "./search.view"

export function SearchFeature() {
  const { renderAs, display, instructions, effects } = useSearchController()
  return <SearchView renderAs={renderAs} display={display} instructions={instructions} effects={effects} />
}
```

## Rules

1. Routes import `.feature.tsx`, never `.view.tsx` directly
2. Views are pure — no hooks, no `"use client"`, no imports from React except types
3. Feature component is thin — just destructure + pass props, no logic
4. Props are explicit — destructure and pass individually, don't spread
