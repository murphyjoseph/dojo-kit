# Advanced Commit Patterns

## Multi-File Commits

### Same concern = one commit

Files that work together to implement a single change belong in one commit:

- A component and its styles
- A function and its tests
- A migration and the model it modifies
- An API endpoint, its route registration, and its types

### Different concerns = split

If files address separate concerns, split into separate commits even if you worked on them at the same time:

- A bug fix in one module + a new feature in another
- A refactor + a behavior change
- A dependency update + code that uses the new API

### Strategies for splitting

- **Stage specific files**: `git add src/auth.ts src/auth.test.ts` then commit, then stage the next group
- **Stage partial files**: `git add -p` to stage individual hunks within a file when it contains changes for multiple concerns
- **Review before staging**: always run `git diff` to understand the full scope before deciding how to split

## Breaking Changes

Mark commits that break backwards compatibility:

### Using the footer

```
feat(api): change user endpoint response format

BREAKING CHANGE: The /users endpoint now returns paginated results
wrapped in a `data` array instead of a flat array. Clients must
update to read `response.data` instead of using the response directly.
```

### Using the `!` suffix

```
feat(api)!: change user endpoint response format
```

The `!` after the scope (or after the type if no scope) signals a breaking change in the subject line. Use this for concise messages. Use the `BREAKING CHANGE:` footer when you need to explain the migration path.

### What counts as breaking

- Removing or renaming a public API, function, or export
- Changing the type signature of a public function
- Changing the shape of a response, config, or data structure
- Removing support for a previously supported option or environment
- Changing default behavior that consumers depend on

### Always explain migration

When introducing a breaking change, the commit body should explain:

1. What broke and why
2. What consumers need to change
3. Any automated migration path available

## Reverts

Use `revert` type and reference the original commit:

```
revert: feat(api): add pagination to user list endpoint

Reverts commit a1b2c3d. The cursor-based pagination broke
backwards compatibility with the mobile client.
```

- The description should match the original commit's subject
- The body should include the SHA being reverted and explain why

## Co-Authored Commits

Add a `Co-Authored-By` trailer for pair programming when multiple people contributed:

```
feat(search): add fuzzy matching to product search

Co-Authored-By: Alice Smith <alice@example.com>
```

- Place on its own line in the footer section (after a blank line from the body)
- Use the contributor's full name and commit email
- Multiple co-authors get separate lines
- Do not add AI tools as co-authors — the committer reviews and owns the code

## Fixup and Amend

### When to amend

- **Only when the user explicitly requests it** — never amend on your own initiative
- **Never after a hook failure** — a failed pre-commit hook means the commit didn't happen, so `--amend` would modify the *previous* commit and risk destroying work
- **Never on published commits** — if the commit has been pushed, create a new commit instead

### After a hook failure

When `commitlint` or another pre-commit hook rejects a commit:

1. The commit **did not happen** — there is nothing to amend
2. Fix the issue (e.g., correct the message format)
3. Re-stage if needed (`git add`)
4. Create a **new** commit — do not use `--amend`

### Fixup commits

Use `fixup!` prefix when making small corrections to a recent commit that hasn't been pushed:

```
fixup! feat(auth): add OAuth2 login
```

These can later be squashed with `git rebase --autosquash` if the user chooses. Only create fixup commits when the user requests them.

## Commit Frequency

### Small and frequent > rare and large

- Commit after each logical unit of work, not at the end of a session
- A feature with multiple steps should produce multiple commits
- Each commit should be independently understandable from its diff and message

### Rough heuristics

| Scenario | Typical commits |
|---|---|
| Small bug fix | 1 commit |
| Simple feature | 1-2 commits |
| Feature with tests | 2-3 commits (implementation, tests, docs if needed) |
| Multi-step refactor | 1 per transformation step |
| Large feature | 3-8 commits, one per logical milestone |

### When in doubt

If a commit's diff is hard to summarize in one short description, it probably should be split. If you find yourself using "and" in the description, consider whether those are two separate commits.
