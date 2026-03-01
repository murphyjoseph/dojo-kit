# 003 — Project Standards (Hard Rules)

## Decision

The `project-standards` skill encodes non-negotiable rules that apply to every project regardless of stack.

## Rules (so far)

- **Never install globally.** Every dependency goes in `devDependencies` or `dependencies` at the project/package level. No `npm install -g`. No exceptions.
- **No "shared" packages.** Packages follow single responsibility. Name them by what they do (`errors`, `logger`, `react-utils`), not `shared` or `common` or `utils`.
- **Packages declare their boundary through their type.** A `platform` package importing React is a bug. A `react` package has React as a peer dep, not a direct dep.
- **File naming is kebab-case.**
- **Never commit secrets.** No `.env`, credentials, API keys.
- **Use the project's package manager.** Detected from lockfile, never mixed.
- **Conventional commits enforced via commitlint.**

## Open Question

More rules will emerge as we build. This list is a starting point.
