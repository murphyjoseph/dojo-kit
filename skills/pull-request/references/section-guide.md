# PR Template Section Guide

Detailed guidance for populating each section of the PR template at `assets/template.md`.

## Related Links

Provide links that give reviewers context before reading code.

**What to include:**

- **Deploy preview** — if the project generates preview URLs, include one. If not available yet, omit rather than writing "pending".
- **Ticket/issue links** — link to the Jira, Asana, Linear, or GitHub issue that motivated this work. Use the full URL, not just the issue number.
- **User story or spec** — if there's a design doc, RFC, or user story, link it here.

**How to find links:**

- Check commit messages for issue references (`Refs: #123`, `Closes #456`)
- Ask the user if no ticket is apparent — PRs tied to tracked work should reference their ticket
- Check CI output for deploy preview URLs if the project uses preview deploys

**When to write "N/A":** only if the change is purely internal (e.g., a dev tooling update) with no associated ticket or preview.

## What

A bulleted list of high-level changes. This is the quick summary a reviewer reads first.

**How to populate:**

1. Run `git log main..HEAD --oneline` to see all commits
2. Group related commits into logical changes (don't list one bullet per commit)
3. Write each bullet using **past tense action verbs**: Added, Updated, Refactored, Moved, Removed, Fixed, Replaced, Extracted, Renamed
4. Describe changes at the feature level, not the file level

**Good bullets:**

- Added email verification step to the signup flow
- Refactored auth middleware into separate token and session validators
- Removed deprecated `legacyLogin` endpoint and its tests

**Bad bullets:**

- Changed `auth.ts` (too vague, file-level)
- Updated code (meaningless)
- Added `verifyEmail` function to `signup.ts` and added `EmailVerification` component to `components/` and updated `routes.ts` (too granular — collapse into one logical bullet)

**Guideline:** aim for 2-6 bullets. If you have more than 6, the PR may need splitting.

## Why

Explain the motivation behind the changes. Pull from commit bodies, issue descriptions, or the user.

**Common patterns:**

- **New feature**: "Requested in [TICKET-123] — users need to verify their email before accessing the dashboard."
- **Bug fix**: "Users reported being logged out unexpectedly when their session token expired during an active request."
- **Refactor**: "The auth middleware was handling both token validation and session management, making it difficult to test either in isolation."
- **Design feedback**: "Design review flagged the signup form as needing a verification step before account activation."
- **Fast-follow**: "Follow-up to #87 which added the base signup flow — this PR adds the email verification that was deferred."

**How to write it:**

- Start with the problem or request, not the solution
- One to three sentences is usually sufficient
- If the motivation isn't obvious from the diff, ask the user rather than guessing

## How

Describe the approach taken. This is the narrative — how you arrived at the implementation, not a restatement of what changed.

**What to cover:**

- **Pairing or collaboration**: "Paired with @teammate on the token refresh logic"
- **Alternatives considered**: "Tried using middleware chaining but it didn't support async validators, so we used a wrapper pattern instead"
- **Key resources**: "Followed the OAuth 2.0 PKCE spec (RFC 7636) for the token exchange"
- **APIs or libraries used**: "Used `nodemailer` for sending verification emails and `nanoid` for generating tokens"
- **Migration or data considerations**: "Existing users without verified emails are grandfathered in — verification only applies to new signups"

**When it's straightforward:** if the "how" is obvious from the "what" (e.g., a typo fix), a single sentence like "Straightforward text correction" is fine.

## Designs

Visual context for reviewers. This section prevents reviewers from having to check out the branch just to see what something looks like.

**When to include (any visual change):**

- New UI components or pages
- Layout changes, spacing adjustments, responsive behavior
- Color, typography, or visual design updates
- Animation or transition changes
- Loading states, empty states, error states

**What to include:**

- Screenshots of before/after (side by side when possible)
- Links to Figma mockups, wireframes, or prototypes
- Short screen recordings for interaction or animation changes (use GIFs or video links)

**When to write "N/A":**

- Backend-only changes (API, database, infrastructure)
- Configuration or CI/CD changes
- Code refactors with no visual impact
- Test-only changes
- Documentation updates

## Test Steps

A checklist of manual verification steps. Be specific enough that a reviewer can follow them without prior context.

**How to write good test steps:**

1. **Start with setup** — feature flags to enable, env variables to set, seed data to create
2. **Specify navigation** — exact URLs, pages, or entry points: "Go to `/settings/email`"
3. **Describe actions** — what to click, type, or interact with: "Click the 'Verify Email' button"
4. **State expected results** — what the reviewer should see: "A confirmation toast appears and the status changes to 'Verified'"
5. **Cover edge cases** — invalid inputs, empty states, error conditions: "Submit the form with an invalid email — an inline error should appear"
6. **Use checkbox format** — `- [ ]` so reviewers can track progress

**Example:**

```markdown
- [ ] Go to `/signup`
- [ ] Complete the signup form with a valid email
- [ ] Check that a verification email arrives (use Mailtrap in staging)
- [ ] Click the verification link in the email
- [ ] Confirm redirect to `/dashboard` with a "Email verified" toast
- [ ] Try signing up again with the same email — should show "Email already registered"
```

**For non-UI changes:** test steps still apply. For API changes: provide `curl` commands. For config changes: describe how to verify the config takes effect.

## Other Notes

Capture anything that doesn't fit in the above sections but is important for reviewers.

**Common uses:**

- **Known limitations**: "The verification email doesn't support i18n yet — planned for the next sprint"
- **Planned fast-follows**: "A follow-up PR will add rate limiting to the verification endpoint"
- **Open questions**: "Should we auto-redirect to `/dashboard` after verification or show an interstitial?"
- **Deliberate omissions**: "Didn't update the legacy login flow — it's being deprecated in Q2"
- **Reviewer guidance**: "The changes to `middleware.ts` are the most critical — everything else follows from that"

**When to write "N/A":** if there's truly nothing else to note. But consider whether there are open questions or known limitations before writing "N/A" — this section is often more useful than people think.

## General Rules

- **Never leave template placeholder text** — every section gets real content or "N/A"
- **Keep section headers exactly as they appear in the template** — `## Related Links`, `## What`, etc.
- **Write for reviewers who don't have context** — assume they haven't seen the ticket or discussion
- **Link rather than duplicate** — reference tickets and docs by URL rather than copying their content into the PR
