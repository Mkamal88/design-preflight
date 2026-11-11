# Stack detection

Run `scripts/detect_stack.sh <repo-root>`. It prints the languages, frameworks, data layer, cache, background work, infrastructure, test tools and project context files it finds. Then use the tables below.

## Where the schema lives

| Stack | Schema and migrations |
|---|---|
| Prisma | `schema.prisma`, `prisma/migrations/` |
| TypeORM | `*.entity.ts`, `migrations/` |
| Sequelize | `models/`, `migrations/` |
| Drizzle | `schema.ts`, `drizzle/` |
| Mongoose | `*.model.ts`, `models/` (indexes in `schema.index(...)`) |
| Django | `models.py`, `*/migrations/` |
| SQLAlchemy | model modules, `alembic/versions/` |
| Rails | `db/schema.rb` or `db/structure.sql`, `db/migrate/` |
| Laravel | `database/migrations/` |
| Spring / Hibernate | `@Entity` classes, Flyway `db/migration/` or Liquibase changelogs |
| EF Core | `DbContext`, `Migrations/` |
| GORM / sqlx (Go) | struct tags, `migrations/` |
| Raw SQL | `*.sql` files |

## Counting queries (for N+1 and chatty code)

| Stack | Switch |
|---|---|
| Prisma | `new PrismaClient({ log: ['query'] })` or `DEBUG=prisma:query` |
| TypeORM | `logging: ['query']` |
| Sequelize | `logging: console.log` |
| Drizzle | `drizzle(client, { logger: true })` |
| Knex | `DEBUG=knex:query` |
| Mongoose | `mongoose.set('debug', true)` |
| Django | `assertNumQueries`, `connection.queries` with `DEBUG=True`, django-debug-toolbar |
| SQLAlchemy | `create_engine(..., echo=True)` |
| Rails | development log, the `bullet` gem |
| Laravel | `DB::enableQueryLog()`, Laravel Debugbar |
| Hibernate | `spring.jpa.show-sql=true`, `hibernate.generate_statistics=true` |
| EF Core | `optionsBuilder.LogTo(Console.WriteLine)` |
| GORM | `db.Debug()` |

Best evidence: run an existing test of the endpoint with logging on and count the queries.

## Query plans

| Engine | Command |
|---|---|
| PostgreSQL | `EXPLAIN (ANALYZE, BUFFERS) <query>;` |
| MySQL 8.0.18+ | `EXPLAIN ANALYZE <query>;` |
| SQLite | `EXPLAIN QUERY PLAN <query>;` |
| SQL Server | `SET STATISTICS IO, TIME ON;` plus the actual execution plan |
| MongoDB | `db.collection.find(...).explain("executionStats")` |

Warning signs: a sequential or full scan on a big table, "Rows Removed by Filter" far larger than the rows returned, a sort spilling to disk, nested loops over many rows, an index that exists but is not used.

`EXPLAIN ANALYZE` runs the query. Use it only on a local database, and wrap writes in a transaction you roll back.

## Stack-specific things to check

| Stack | Check |
|---|---|
| Node.js | `await` in loops, unhandled promise rejections, blocking CPU work on the event loop, pool size against the number of instances |
| Python (sync) | worker count, blocking I/O in async views, ORM lazy loading in templates and serializers |
| Rails | `includes`/`preload` on lists, callbacks with side effects, `find_each` for batches |
| Django | `select_related`/`prefetch_related`, `.only()`/`.defer()`, `iterator()` for big querysets |
| Java / Spring | lazy loading outside a transaction, `@Transactional` scope, the fetch type on collections |
| Go | context timeouts, rows closed, goroutine leaks |
| GraphQL | resolvers per field (use a dataloader), query depth and cost limits |
| Serverless | connection pooling (RDS Proxy, PgBouncer), cold starts, package size |
| Frontend SPA | request waterfalls, bundle size, list virtualisation |
