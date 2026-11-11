# Lens: database

Work from the Change Map. For each check: find the real model or query, decide whether it matters at the stated scale, and record the evidence.

## 1. Access patterns and indexes

- List every new or changed query: filter columns, sort, joins, expected row counts.
- Is there an index whose **leading columns** match the filter? Order: equality columns first, then range, then sort. In a multi-tenant app the tenant column usually comes first.
- Business rules such as "one active X per Y" are enforced by a unique index (or a partial unique index), not only in code.
- Soft-delete or status filters on large tables (`deleted_at IS NULL`, `status = 'active'`) → a partial index.
- Foreign keys used in joins or cascades have an index. PostgreSQL does not create one for you.
- Does the spec add indexes that nothing reads? Each one slows down writes.

Where to look: schema files and migrations; search for `@@index`, `@@unique`, `index=True`, `add_index`, `CREATE INDEX`, `@Index`.

Evidence: the query plus the list of existing indexes. Best: an EXPLAIN plan that shows the scan.

## 2. Query shape

- **N+1:** queries inside loops, lazy relations read per item, an `await` on the database inside `for` or `map`, GraphQL resolvers per field (use a dataloader).
- **Over-fetching:** loading every column and relation to use two fields; large text or JSON columns loaded in list views.
- **Unbounded queries:** list endpoints without a limit, `findMany()` without `take`, exports that load everything into memory (use streaming, a cursor or batches).
- **Pagination:** OFFSET on deep pages gets slower as the offset grows. Use keyset (cursor) pagination for large or infinite lists.
- **Counts:** `COUNT(*)` on a big table on every request → an estimate, a stored counter, or no total.
- **Aggregates on a hot path:** when reads far outnumber writes, precompute them (summary table, materialized view).
- **Text search:** `LIKE '%x%'` → a trigram or full-text index before a separate search engine.

## 3. Transactions, concurrency and integrity

- External calls (HTTP, AI, email, storage) **inside** a transaction hold locks and connections. Move them out. Use the outbox pattern for side effects that must match the write.
- Check-then-insert races → unique constraint plus upsert, `SELECT ... FOR UPDATE`, or optimistic locking with a version column.
- Writes that may be retried need an idempotency key with a unique constraint.
- Steps that must succeed or fail together are really in one transaction.
- Cascading deletes or updates that fan out to large tables.

## 4. Schema design

- **Types:** money as integer or decimal, never float; timestamps stored in UTC (with time zone); enums against lookup tables, depending on how often the values change.
- **JSON columns:** fine for opaque data. Wrong for fields you filter, join or validate; use real columns (or a JSON index if the shape is truly dynamic).
- **Denormalisation:** only for a measured read path, and say how the copy stays consistent.
- **Growth:** tables that grow with every event or request need retention, archiving or time-based partitioning.
- **Multi-tenancy:** the tenant ID is on every tenant-owned table and in every unique constraint and index where it belongs. Consider row-level security when a leak between tenants would be serious.

## 5. Migrations

- Additive first (expand, migrate, contract). Do not rename or drop a column in the same release as the code that stops using it.
- Operations that lock large tables: changing a column type, adding NOT NULL without a default on older engines, creating an index without `CONCURRENTLY` (PostgreSQL) or online DDL (MySQL).
- Backfills run in batches, outside the migration transaction where possible.
- The rollback steps are written down.

## 6. Connections and load

- Pool size against the number of instances and workers. Serverless needs a pooler (PgBouncer, RDS Proxy).
- Long reports on the primary database → a read replica or an off-peak job.
- Hot rows (a shared counter, a single settings row) cause lock contention.

## Fix ladder (cheapest first)

1. Fix the query: fewer columns, batching, no N+1.
2. Add or change an index.
3. Change pagination or limits.
4. Precompute in the same database: summary table, materialized view, scheduled job.
5. Cache outside the database (see `lens-latency.md` and `constraint-challenging.md`).
6. Read replica or partitioning.
7. A different store for the job: search engine, analytics warehouse, time-series database.
