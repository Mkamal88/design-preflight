# Report template

Fill in this structure. Leave out sections that are empty, except "Not checked".

````markdown
# Design preflight: <ID> — <title>

Source: <link> · Mode: <pre | diff | batch> · Date: <YYYY-MM-DD> · Scale assumed: <...>

## Verdict: <Ready | Ready with changes | Needs rework>

<Two or three sentences: the main reason, and the single most important change.>

## Top findings

| # | Severity | Finding | Evidence | Fix | Effort | Priority |
|---|---|---|---|---|---|---|
| 1 | Blocker | ... | `path:line` (Observed) | ... | S | 20 |

### 1. <finding title>

- **Where:** `path:line` · **Lens:** db · **Evidence:** Measured / Observed / Inferred
- **Problem:** ...
- **Why it matters here:** ... (at the stated scale)
- **Fix:** ... (specific: the index columns, the query, the function)
- **Verify by:** the test or measurement that proves the fix

(Up to 5 findings in this section.)

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

- Sort by priority, with Blockers first.
- One finding is one problem. Merge duplicates that came from different lenses.
- Fixes are specific: name the columns, the query, the function, the file.
- Keep it short. A reviewer should read the verdict and top findings in under three minutes.

## Batch mode

One table, sorted by risk:

| Item | Verdict | Top risk | Effort | Full review? |
|---|---|---|---|---|
