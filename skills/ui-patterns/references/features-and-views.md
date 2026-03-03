# Features & Views

How to separate "deciding what to show" from "showing it" so that business logic and rendering don't collide.

## Quick Reference

| Rule | Description |
|---|---|
| Four layers | Controller → Presenter → Feature → View |
| Presenter is a pure function | Input data → output contract, no hooks or side effects |
| Feature is the wiring layer | Calls controller, passes props to view, owns `"use client"` |
| View renders from props | No hooks, no `"use client"`, no data fetching, narrows on `renderAs` |
| View contract has four sections | `renderAs`, `display`, `instructions`, `effects` |

## The Four Layers

### Controller

Fetches data, manages state, owns side effects. Uses framework primitives (hooks, routers, context). Thin — calls the other two layers and wires them together. Lives in a `.controller.ts` file.

```typescript
// features/team/members/team-members.controller.ts
export function useTeamMembers(teamId: string) {
  const { data, isLoading, error } = useQuery(['team', teamId], () =>
    getTeamMembers(teamId)
  );
  const permissions = usePermissions();

  const contract = presentTeamMembers({
    data: data ?? null,
    isLoading,
    error: error ?? null,
    permissions,
  });

  return contract;
}
```

### Present

A pure function that takes raw data and returns a typed view contract. No hooks, no side effects, no framework imports.

```typescript
// features/team/members/team-members.presenter.ts
export function presentTeamMembers(input: {
  data: TeamMember[] | null;
  isLoading: boolean;
  error: ErrorBase | null;
  permissions: Permissions;
}): TeamMembersContract {
  if (input.isLoading) {
    return { renderAs: 'loading' };
  }

  if (input.error) {
    return {
      renderAs: 'error',
      display: {
        errorMessage: input.error.displayMessage ?? 'Failed to load team members',
      },
      effects: {
        onRetry: undefined, // controller will provide this
      },
    };
  }

  if (!input.data || input.data.length === 0) {
    return {
      renderAs: 'empty',
      display: {
        emptyMessage: 'No team members yet',
      },
      instructions: {
        showInvitePrompt: input.permissions.canInvite,
      },
    };
  }

  return {
    renderAs: 'content',
    display: {
      members: input.data.map((member) => ({
        fullName: `${member.firstName} ${member.lastName}`,
        roleLabel: formatRole(member.role),
        joinedDate: formatDate(member.joinedAt),
        avatarUrl: member.avatarUrl,
      })),
      memberCount: `${input.data.length} members`,
    },
    instructions: {
      showEditButton: input.permissions.canEdit,
      showRemoveButton: input.permissions.canRemove,
    },
  };
}
```

**Testable with plain assertions:**

```typescript
const contract = presentTeamMembers({
  data: null, isLoading: true, error: null, permissions: defaultPermissions,
});
expect(contract.renderAs).toBe('loading');
```

### Feature

The `"use client"` boundary. Calls the controller hook, destructures the contract, and passes props to the view. Contains no logic — just wiring. Lives in a `.feature.tsx` file.

```typescript
// features/team/members/team-members.feature.tsx
"use client"

import { useTeamMembers } from "./team-members.controller"
import { TeamMembersView } from "./team-members.view"

export function TeamMembersFeature({ teamId }: { teamId: string }) {
  const contract = useTeamMembers(teamId)
  return <TeamMembersView {...contract} />
}
```

**Routes import the feature, not the view.** The feature component is the public entry point.

### View

Receives the contract as props and draws it. No hooks, no `"use client"`, no data fetching, no business logic. Narrows on `renderAs`. Lives in a `.view.tsx` file.

```typescript
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
```

## View Contract Type

```typescript
type TeamMembersContract =
  | { renderAs: 'loading' }
  | {
      renderAs: 'error';
      display: { errorMessage: string };
      effects: { onRetry: (() => void) | undefined };
    }
  | {
      renderAs: 'empty';
      display: { emptyMessage: string };
      instructions: { showInvitePrompt: boolean };
    }
  | {
      renderAs: 'content';
      display: {
        members: Array<{
          fullName: string;
          roleLabel: string;
          joinedDate: string;
          avatarUrl: string;
        }>;
        memberCount: string;
      };
      instructions: {
        showEditButton: boolean;
        showRemoveButton: boolean;
      };
    };
```

### Contract sections

| Section | Contains | Who computes it |
|---|---|---|
| `renderAs` | Discriminated union — which visual mode | Presenter |
| `display` | Formatted, render-ready data (strings, not raw objects) | Presenter |
| `instructions` | Boolean flags the view checks | Presenter |
| `effects` | Callbacks the view can fire | Controller provides, presenter passes through |

## Debugging with the Contract

When something looks wrong on screen:

1. **Inspect the contract the view received.** Log it or check in devtools.
2. **If the contract is correct** → the bug is in the view's rendering
3. **If the contract is wrong** → the bug is in the presenter
4. There is no third option.

## Decision Guide

| Situation | Action |
|---|---|
| Component has conditional logic beyond form validation | Use feature/view pattern |
| Component computes display values from raw data | Extract a presenter |
| Component has permission-based UI (show/hide buttons) | `instructions` in the contract |
| Component has multiple visual states (loading, empty, error, content) | `renderAs` discriminated union |
| Static component that receives props and renders | No pattern needed |
| Layout wrapper or design system primitive | No pattern needed |
| Form with validation and submission | Use form pattern, not feature/view |
| Same data drives different views (card vs detail) | Share the presenter, swap the view |
| Storybook story needs hardcoded data | Pass a contract object directly to the view |
