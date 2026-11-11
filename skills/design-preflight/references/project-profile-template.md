# Project profile template

A project profile tells the skill what "fast enough" and "allowed" mean for one repository. Copy the block below into `.design-preflight.md` at the repository root and edit it. Every section is optional. Keep it short, and link to `AGENTS.md` or decision records instead of copying them.

```markdown
# Design preflight profile

## Scale (now → in 12 months)
- Tenants: 30 → 150
- Users: 5k → 40k (peak concurrent: 800)
- Peak API load: 50 → 300 requests per second
- Largest tables: orders 200k rows (+10k a month), events 5M rows (+1M a month)

## Latency budgets
- Interactive API p95: 300 ms
- Report export: under 30 s, in the background

## Hard constraints (with their source)
- No new infrastructure (Redis, queues) without a tech lead decision: AGENTS.md, "Architecture rules"
- PostgreSQL only, accessed through the ORM; no SQL built from strings

## Preferences
- Background work: job table in the database plus a worker in the app
- Migrations are additive (expand, then contract in a later release)

## Decided and rejected proposals
- 2026-10-02 Redis for sessions: rejected. Sessions in PostgreSQL are fast enough at the current scale. Revisit at 2k concurrent users.

## Measurement environment
- Local database: `docker compose up -d postgres`, then `npm run db:seed`
- Query log: `DEBUG=prisma:query`
- Never measure against: staging, production

## Commands
- Type check: `npm run typecheck`
- Tests: `npm test`

## Review settings
- Lenses always on: db, security
- Report folder: docs/preflight/
- Issue tracker: Jira, project key ACME
```
