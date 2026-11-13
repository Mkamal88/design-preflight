# Design preflight: ACME-142 — Export invoices to CSV

> An example report for a made-up project, to show the output format. The paths, numbers and findings are illustrative.

Source: Jira ACME-142 · Mode: pre · Date: 2026-11-12 · Scale assumed: 120 tenants, largest tenant 400k invoices

## What the ticket asks

Finance managers need to download all invoices for a date range as a CSV file, so they can reconcile them in their accounting tool without asking support for an export.
Who uses it: finance managers in each tenant · Out of scope: PDF export

## Verdict: Ready with changes

The export can be built on the existing job worker, but as written it loads every invoice into memory inside the request and filters by a column with no index. Moving it to a background job with a streamed, keyset-paginated query is the one change that matters most.

## Top findings

| # | Severity | Finding | Evidence | Fix | Effort | Priority |
|---|---|---|---|---|---|---|
| 1 | Blocker | Export runs inside the HTTP request and loads all rows | `src/invoices/router.ts:88` (Observed) | Background job + streamed file | M | 10 |
| 2 | Should | No index for `(tenant_id, issued_at)` | `prisma/schema.prisma:212`, EXPLAIN (Measured) | Composite index, created concurrently | S | 20 |
| 3 | Should | N+1 on customer names | `src/invoices/service.ts:140` (Observed) | Join in one query | S | 16 |

### 1. Export runs inside the HTTP request

- **Where:** `src/invoices/router.ts:88` · **Lens:** latency · **Evidence:** Observed
- **Problem:** the spec's "download button" maps naturally to a `GET` that builds the file in memory. For the largest tenant that is 400k rows, about 180 MB, and over a minute of work.
- **Why it matters here:** the load balancer times out at 60 s, and two exports at once would exhaust a 512 MB container.
- **Fix:** add an `invoice_export` job to the existing `jobs` table worker (`src/jobs/worker.ts`); stream rows to object storage in batches of 1,000; email or notify a signed download link.
- **Verify by:** integration test with 50k seeded invoices; memory stays under 100 MB.

### 2. Missing composite index

- **Where:** `prisma/schema.prisma:212` · **Lens:** db · **Evidence:** Measured
- **Problem:** `WHERE tenant_id = $1 AND issued_at BETWEEN $2 AND $3` uses a sequential scan: 2.1 s on 3M rows locally.
- **Fix:** `@@index([tenantId, issuedAt])`, created with `CREATE INDEX CONCURRENTLY` in a hand-edited migration. After: 14 ms.
- **Verify by:** EXPLAIN shows an Index Scan.

### 3. N+1 on customer names

- **Where:** `src/invoices/service.ts:140` · **Lens:** db · **Evidence:** Observed
- **Problem:** `customer` is loaded per invoice inside the loop: one query per row.
- **Fix:** `include: { customer: { select: { name: true } } }` in the batch query.
- **Verify by:** query count in the export test goes from N+1 to N/1000.

## Changes to propose for the spec

- Acceptance criterion 2 "export is fast" cannot be tested → "An export of 100k invoices completes within 2 minutes and the user is notified."
- Missing: who may export (admins only?), and whether exports include cancelled invoices.

## Constraint-challenging proposals

### P-1: Managed queue for exports (SQS)

- **Rule affected:** AGENTS.md, "Background work uses database tables"
- **Problem:** none at the stated scale. The `jobs` table handles about 5 jobs per second today.
- **Recommendation:** do not adopt. Revisit when job volume passes 50 per second or exports need separate scaling.

## Not checked

- Frontend download flow (no UI design attached to the ticket).
- Object storage costs.
