---
name: pull-request
description: Guide for creating well-structured pull requests using the project
  PR template. Use when creating a PR, writing PR descriptions, deciding how to
  scope a PR, or populating PR template sections.
---

# Pull Request Guide

Create well-structured pull requests that help reviewers understand what changed, why, and how to verify it. This project has a PR template at `assets/template.md` that must be followed. The first two lines of that template (credit comment and ignore instruction) should be excluded from the PR body.

## PR Template Sections

Every PR body must include these sections in order:

| Section | What it expects |
|---|---|
| **Related Links** | Deploy preview, ticket/issue links, user story references |
| **What** | Bulleted list of high-level changes using past tense action verbs |
| **Why** | Motivation for the changes — business need, bug, refactor rationale |
| **How** | Narrative of the approach taken — pairing, alternatives tried, resources used |
| **Designs** | Screenshots, mockups, wireframes, or prototypes for visual changes |
| **Test Steps** | Checklist of manual verification steps with specific URLs, actions, and expected results |
| **Other Notes** | Known limitations, planned fast-follows, open questions for reviewers |

When a section is not applicable (e.g., no designs for a backend-only PR), replace the placeholder content with "N/A" rather than removing the section header.

## PR Creation Workflow

Follow these steps when creating a pull request:

1. **Review all changes on the branch** — run `git log main..HEAD --oneline` for commit summary and `git diff main...HEAD` for the full diff. Read both carefully before writing anything.
2. **Assess scope** — determine if the branch represents one concern. If it contains unrelated changes, consider splitting into separate PRs before proceeding.
3. **Populate each template section** — analyze the commits and diff to fill every section. Do not leave placeholder text from the template — replace each section with real content or "N/A".
4. **Choose a PR title** — concise (under 70 characters), imperative mood, descriptive of the overall change. Not a copy of a single commit message if the PR has multiple commits.
5. **Create the PR** — use `gh pr create` with a heredoc for the body:
   ```bash
   gh pr create --title "Add user authentication flow" --body "$(cat <<'EOF'
   ## Related Links
   ...

   ## What
   ...
   EOF
   )"
   ```
6. **Verify and return** — confirm the PR was created successfully and return the URL to the user.

## How to Scope PRs

Each pull request should represent **one concern**:

- **Feature PRs** contain all code, tests, and docs for one feature
- **Bug fix PRs** address one bug with its regression test
- **Refactor PRs** restructure code without changing behavior
- **Config/infra PRs** update build, CI, or tooling in isolation

**When to split:** if you struggle to write a concise title that covers everything, or the "What" section has items that serve different purposes, the PR likely needs splitting. A PR with both a new feature and an unrelated bug fix should be two PRs.

PR scope is broader than commit scope — a single PR may contain multiple commits that together deliver one concern.

## Writing Good PR Titles

- **Imperative mood**: "Add auth flow" not "Added auth flow" or "Adds auth flow"
- **Under 70 characters** — titles appear in lists and notifications
- **Summarize the overall change** — if the PR has three commits, the title captures the theme, not one commit's message
- **Be specific**: "Fix login redirect for expired sessions" beats "Fix login bug"
- **No type prefix** — unlike commits, PR titles don't use `feat:` / `fix:` prefixes

## References

- **`references/section-guide.md`** — Detailed guidance for populating each PR template section, including what to analyze in the diff, common patterns per section, and examples of good content. Read when filling out a PR description for the first time or when unsure what belongs in a section.
