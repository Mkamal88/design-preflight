# Report template

Fill in this structure. Leave out sections that are empty, except "Not checked".

````markdown
# Design preflight: <ID> — <title>

Source: <link> · Mode: <pre | diff | batch> · Date: <YYYY-MM-DD> · Scale assumed: <...>

## What the ticket asks

<Two sentences in business terms: who needs what, and why.>
Who uses it: <...> · Out of scope: <... only if the ticket says>

## Verdict: <Ready | Ready with changes | Needs rework>

<Two or three sentences: the main reason, and the single most important change.>

## Top findings

| # | Severity | Finding | Evidence | Fix | Effort | Priority | Status |
|---|---|---|---|---|---|---|---|
| 1 | Blocker | ... | `path:line` (Observed) | ... | S | 20 | Open |

### 1. <finding title>

- **Where:** `path:line` · **Lens:** db · **Evidence:** Measured / Observed / Inferred · **Status:** Open / In PR #n / Conflicts with PR #n
- **Problem:** ...
- **Why it matters here:** ... (at the stated scale)
- **Fix:** ... (specific: the index columns, the query, the function)
- **Verify by:** the test or measurement that proves the fix

(Up to 5 findings in this section.)

## In-flight work

| PR | Item | Branch → base | Draft | Overlaps this spec | Note |
|---|---|---|---|---|---|
| #57 | ABC-120 (parent) | `abc-120-audit-model` → `main` | No | `prisma/schema.prisma` | Adds the same index as finding 3 |

<Or: "No open pull requests found for ABC-123 or its N linked items (searched with gh).">

## Changes to propose for the spec

- Acceptance criterion 3 cannot be tested as written → "<new wording>"
- Missing: <edge case, permission, migration, failure handling>
- Split: <part> into its own ticket, because ...

## Constraint-challenging proposals

<Decision records from constraint-challenging.md, or: "None. Within-rules options are enough at this scale.">

## Change map

| Area | Files | Notes |
|---|---|---|
| Entry points | ... | |
| Data | ... | |
| Services | ... | |
| Closest existing pattern | ... | |
| Tests today | ... | |

## Spec coverage (diff mode only)

| Criterion | Implemented in | Tested in | Status |
|---|---|---|---|

## Not checked

<Lenses skipped and why; what needs measuring and how; access you did not have.>

## Appendix: other findings

<One line each: severity, finding, evidence, fix.>
````

## Rules

- "What the ticket asks" is at most three lines, in plain business language: no code, tables or endpoints, and no copy of the description or the acceptance criteria. It is your own understanding, so the reader can catch a misreading before the findings. If the goal is unclear or can be read two ways, write that here instead of guessing, and add it to "Changes to propose for the spec".
- Sort by priority, with Blockers first.
- A finding already fixed in an open pull request stays in the report with status `In PR #n`, so the reviewer of that pull request can check it.
- A conflict between two open pull requests is a finding of its own.
- One finding is one problem. Merge duplicates that came from different lenses.
- Fixes are specific: name the columns, the query, the function, the file.
- Keep it short. A reviewer should read the verdict and top findings in under three minutes.

## Batch mode

One table, sorted by risk:

| Item | Verdict | Top risk | Effort | Full review? |
|---|---|---|---|---|
